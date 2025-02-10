<script>
import {
  GlAlert,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSearchBoxByClick,
  GlSprintf,
  GlTable,
  GlFormCheckbox,
  GlTooltipDirective,
} from '@gitlab/ui';
import { debounce, isNumber, isUndefined } from 'lodash';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, __, n__, sprintf } from '~/locale';
import { HTTP_STATUS_TOO_MANY_REQUESTS } from '~/lib/utils/http_status';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { getGroupPathAvailability } from '~/rest_api';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import { STATUSES } from '../../constants';
import importGroupsMutation from '../graphql/mutations/import_groups.mutation.graphql';
import updateImportStatusMutation from '../graphql/mutations/update_import_status.mutation.graphql';
import bulkImportSourceGroupsQuery from '../graphql/queries/bulk_import_source_groups.query.graphql';
import { NEW_NAME_FIELD, TARGET_NAMESPACE_FIELD, ROOT_NAMESPACE, i18n } from '../constants';
import { StatusPoller } from '../services/status_poller';
import {
  isFinished,
  isAvailableForImport,
  isNameValid,
  isProjectCreationAllowed,
  isSameTarget,
} from '../utils';
import ImportActionsCell from './import_actions_cell.vue';
import ImportHistoryLink from './import_history_link.vue';
import ImportSourceCell from './import_source_cell.vue';
import ImportStatusCell from './import_status.vue';
import ImportTargetCell from './import_target_cell.vue';

const VALIDATION_DEBOUNCE_TIME = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;
const PAGE_SIZES = [20, 50, 100];
const DEFAULT_PAGE_SIZE = PAGE_SIZES[0];

export default {
  components: {
    GlAlert,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSearchBoxByClick,
    GlFormCheckbox,
    GlSprintf,
    GlTable,
    ImportSourceCell,
    ImportTargetCell,
    ImportStatusCell,
    ImportActionsCell,
    ImportHistoryLink,
    PaginationBar,
    HelpPopover,
    PageHeading,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    sourceUrl: {
      type: String,
      required: true,
    },
    groupPathRegex: {
      type: RegExp,
      required: true,
    },
    jobsPath: {
      type: String,
      required: true,
    },
    historyPath: {
      type: String,
      required: true,
    },
    historyShowPath: {
      type: String,
      required: true,
    },
    defaultTargetNamespace: {
      type: Number,
      required: false,
      default: null,
    },
  },

  data() {
    return {
      filter: '',
      page: 1,
      perPage: DEFAULT_PAGE_SIZE,
      selectedGroupsIds: [],
      pendingGroupsIds: [],
      reimportRequests: [],
      importTargets: {},
      unavailableFeaturesAlertVisible: true,
      helpUrl: helpPagePath('user/group/import/_index', {
        anchor: 'visibility-rules',
      }),
      shouldMigrateMemberships: true,
    };
  },

  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    bulkImportSourceGroups: {
      query: bulkImportSourceGroupsQuery,
      variables() {
        return { page: this.page, filter: this.filter, perPage: this.perPage };
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    availableNamespaces: {
      query: searchNamespacesWhereUserCanImportProjectsQuery,
      update(data) {
        return data.currentUser.groups.nodes;
      },
    },
  },

  fields: [
    {
      key: 'selected',
      label: '',
      thClass: 'gl-w-3 !gl-pr-3',
      tdClass: '!gl-pr-3',
    },
    {
      key: 'webUrl',
      label: s__('BulkImport|Source group'),
      // eslint-disable-next-line @gitlab/require-i18n-strings
      thClass: '!gl-pl-0 gl-w-1/2',
      tdClass: '!gl-pl-0',
    },
    {
      key: 'importTarget',
      label: s__('BulkImport|New group'),
      thClass: `gl-w-1/2`,
    },
    {
      key: 'progress',
      label: __('Status'),
      tdAttr: { 'data-testid': 'import-status-indicator' },
    },
    {
      key: 'actions',
      label: '',
    },
  ],

  computed: {
    groups() {
      return this.bulkImportSourceGroups?.nodes ?? [];
    },

    groupsTableData() {
      if (!this.availableNamespaces) {
        return [];
      }

      return this.groups.map((group) => {
        const importTarget = this.importTargets[group.id];
        const status = this.getStatus(group);

        const isGroupAvailableForImport = isFinished(group)
          ? this.reimportRequests.includes(group.id)
          : isAvailableForImport(group) && status !== STATUSES.SCHEDULING;

        const flags = {
          isInvalid:
            (importTarget?.validationErrors ?? []).filter((e) => !e.nonBlocking).length > 0,
          isAvailableForImport: isGroupAvailableForImport,
          isAllowedForReimport: false,
          isFinished: isFinished(group),
          isProjectCreationAllowed: importTarget?.targetNamespace
            ? isProjectCreationAllowed(importTarget.targetNamespace)
            : // When targetNamespace is not selected, we set the flag to undefined (instead of defaulting to true / false)
              // to allow import_actions_cell.vue to use its default prop value.
              undefined,
        };

        return {
          ...group,
          visibleStatus: status,
          importTarget,
          flags: {
            ...flags,
            isUnselectable: !flags.isAvailableForImport || flags.isInvalid,
          },
        };
      });
    },

    hasSelectedGroups() {
      return this.selectedGroupsIds.length > 0;
    },

    hasAllAvailableGroupsSelected() {
      return this.selectedGroupsIds.length === this.availableGroupsForImport.length;
    },

    showImportProjectsWarning() {
      return (
        this.hasSelectedGroups &&
        this.groupsTableData.some(
          (group) =>
            this.selectedGroupsIds.includes(group.id) && !group.flags.isProjectCreationAllowed,
        )
      );
    },

    availableGroupsForImport() {
      return this.groupsTableData.filter((g) => g.flags.isAvailableForImport && !g.flags.isInvalid);
    },

    humanizedTotal() {
      return this.paginationInfo.total >= 1000 ? __('1000+') : this.paginationInfo.total;
    },

    hasGroups() {
      return this.groups.length > 0;
    },

    hasEmptyFilter() {
      return this.filter.length > 0 && !this.hasGroups;
    },

    statusMessage() {
      return this.filter.length === 0
        ? s__('BulkImport|Showing %{start}-%{end} of %{total} that you own from %{link}')
        : s__(
            'BulkImport|Showing %{start}-%{end} of %{total} that you own matching filter "%{filter}" from %{link}',
          );
    },

    paginationInfo() {
      const { page, perPage, total } = this.bulkImportSourceGroups?.pageInfo ?? {
        page: 1,
        perPage: 0,
        total: 0,
      };
      const start = (page - 1) * perPage + 1;
      const end = start + this.groups.length - 1;

      return { start, end, total };
    },

    unavailableFeatures() {
      if (!this.hasGroups) {
        return [];
      }

      return Object.entries(this.bulkImportSourceGroups.versionValidation.features)
        .filter(([, { available }]) => available === false)
        .map(([k, v]) => ({ title: i18n.features[k] || k, version: v.minVersion }));
    },

    unavailableFeaturesAlertTitle() {
      return sprintf(s__('BulkImport| %{host} is running outdated GitLab version (v%{version})'), {
        host: this.sourceUrl,
        version: this.bulkImportSourceGroups.versionValidation.features.sourceInstanceVersion,
      });
    },

    pageInfo() {
      return this.bulkImportSourceGroups?.pageInfo ?? {};
    },
  },

  watch: {
    filter() {
      this.page = 1;
    },

    groups() {
      const table = this.getTableRef();
      const matches = new Set();
      this.groups.forEach((g, idx) => {
        if (!this.importTargets[g.id]) {
          this.setDefaultImportTarget(g);
        }

        if (this.selectedGroupsIds.includes(g.id)) {
          matches.add(g.id);
          this.$nextTick(() => {
            table.selectRow(idx);
          });
        }
      });

      this.selectedGroupsIds = this.selectedGroupsIds.filter((id) => matches.has(id));
    },
  },

  mounted() {
    this.statusPoller = new StatusPoller({
      pollPath: this.jobsPath,
      updateImportStatus: (update) => {
        try {
          this.$apollo.mutate({
            mutation: updateImportStatusMutation,
            variables: {
              id: update.id,
              status: update.status_name,
              hasFailures: update.has_failures,
            },
          });
        } catch (error) {
          Sentry.captureException(error);
        }
      },
    });

    this.statusPoller.startPolling();
  },

  beforeDestroy() {
    this.statusPoller.stopPolling();
  },

  methods: {
    rowClasses(groupTableItem) {
      const DEFAULT_CLASSES = [
        'gl-border-strong',
        'gl-border-0',
        'gl-border-b-1',
        'gl-border-solid',
      ];
      const result = [...DEFAULT_CLASSES];
      if (groupTableItem.flags.isUnselectable) {
        result.push('!gl-cursor-default');
      }
      return result;
    },

    qaRowAttributes(group, type) {
      if (type === 'row') {
        return {
          'data-testid': 'import-item',
          'data-qa-source-group': group.fullPath,
        };
      }

      return {};
    },

    groupsCount(count) {
      return n__('%d group', '%d groups', count);
    },

    setPage(page) {
      this.page = page;
    },

    getStatus(group) {
      if (this.pendingGroupsIds.includes(group.id)) {
        return STATUSES.SCHEDULING;
      }

      return group.progress?.status || STATUSES.NONE;
    },

    hasFailures(group) {
      return group.progress?.hasFailures;
    },

    showHistoryLink(group) {
      // We need to check for `isNumber` to make sure `id` is passed from the backend
      // and not "LOCAL-PROGRESS-${id}" as defined by client_factory.js
      return group.progress?.id && isNumber(group.progress.id);
    },

    updateImportTarget(group, changes) {
      const newImportTarget = {
        ...group.importTarget,
        ...changes,
        ...(changes.targetNamespace
          ? {
              targetNamespace: {
                ...(this.availableNamespaces.find((g) => g.id === changes.targetNamespace.id) ||
                  changes.targetNamespace),
              },
            }
          : {}),
      };

      this.importTargets = {
        ...this.importTargets,
        [group.id]: newImportTarget,
      };
      this.validateImportTarget(newImportTarget);
    },

    async requestGroupsImport(importRequests) {
      const newPendingGroupsIds = importRequests.map((request) => request.sourceGroupId);
      newPendingGroupsIds.forEach((id) => {
        if (!this.pendingGroupsIds.includes(id)) {
          this.pendingGroupsIds.push(id);
        }
      });

      try {
        await this.$apollo.mutate({
          mutation: importGroupsMutation,
          variables: { importRequests },
        });
      } catch (error) {
        if (error.networkError?.response?.status === HTTP_STATUS_TOO_MANY_REQUESTS) {
          newPendingGroupsIds.forEach((id) => {
            this.importTargets[id].validationErrors = [
              { field: NEW_NAME_FIELD, message: i18n.ERROR_TOO_MANY_REQUESTS, nonBlocking: true },
            ];
          });
        } else {
          createAlert({
            message: i18n.ERROR_IMPORT,
            captureError: true,
            error,
          });
        }
      } finally {
        this.pendingGroupsIds = this.pendingGroupsIds.filter(
          (id) => !newPendingGroupsIds.includes(id),
        );
      }
    },

    async importGroup({ group, extraArgs, index }) {
      if (!this.validateImportTargetNamespace(group.importTarget)) {
        return;
      }

      if (group.flags.isFinished && !this.reimportRequests.includes(group.id)) {
        this.validateImportTarget(group.importTarget);
        this.reimportRequests.push(group.id);
        this.$nextTick(() => {
          this.$refs[`importTargetCell-${index}`].focusNewName();
        });
      } else {
        this.reimportRequests = this.reimportRequests.filter((id) => id !== group.id);
        await this.requestGroupsImport([
          {
            sourceGroupId: group.id,
            targetNamespace: group.importTarget.targetNamespace.fullPath,
            newName: group.importTarget.newName,
            migrateMemberships: this.shouldMigrateMemberships,
            ...extraArgs,
          },
        ]);

        const updatedGroup = this.groups?.find((g) => g.id === group.id);

        if (
          updatedGroup.progress &&
          updatedGroup.progress.status === STATUSES.FAILED &&
          updatedGroup.progress.message
        ) {
          this.reimportRequests.push(group.id);
        }
      }
    },

    importSelectedGroups(extraArgs = {}) {
      const importRequests = this.groupsTableData
        .filter((group) => this.selectedGroupsIds.includes(group.id))
        .map((group) => ({
          sourceGroupId: group.id,
          targetNamespace: group.importTarget.targetNamespace.fullPath,
          newName: group.importTarget.newName,
          migrateMemberships: this.shouldMigrateMemberships,
          ...extraArgs,
        }));

      this.requestGroupsImport(importRequests);
    },

    setPageSize(size) {
      this.page = 1;
      this.perPage = size;
    },

    getTableRef() {
      // Acquire reference to BTable to manipulate selection
      // issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1531
      // refs are not reactive, so do not use computed here
      return this.$refs.table?.$children[0];
    },

    preventSelectingAlreadyImportedGroups(updatedSelection) {
      if (updatedSelection) {
        this.selectedGroupsIds = updatedSelection.map((g) => g.id);
      }

      const table = this.getTableRef();
      this.groupsTableData.forEach((group, idx) => {
        if (table.isRowSelected(idx) && group.flags.isUnselectable) {
          table.unselectRow(idx);
        }
      });
    },

    validateImportTargetNamespace(importTarget) {
      if (isUndefined(importTarget.targetNamespace)) {
        // eslint-disable-next-line no-param-reassign
        importTarget.validationErrors = [
          { field: TARGET_NAMESPACE_FIELD, message: i18n.ERROR_TARGET_NAMESPACE_REQUIRED },
        ];
        return false;
      }
      return true;
    },

    validateImportTarget: debounce(async function validate(importTarget) {
      const newValidationErrors = [];
      importTarget.cancellationToken?.cancel();

      if (!this.validateImportTargetNamespace(importTarget)) {
        return;
      }

      if (importTarget.newName === '') {
        newValidationErrors.push({ field: NEW_NAME_FIELD, message: i18n.ERROR_REQUIRED });
      } else if (!isNameValid(importTarget, this.groupPathRegex)) {
        newValidationErrors.push({ field: NEW_NAME_FIELD, message: i18n.ERROR_INVALID_FORMAT });
      } else if (Object.values(this.importTargets).find(isSameTarget(importTarget))) {
        newValidationErrors.push({
          field: NEW_NAME_FIELD,
          message: i18n.ERROR_NAME_ALREADY_USED_IN_SUGGESTION,
        });
      } else {
        try {
          // eslint-disable-next-line no-param-reassign
          importTarget.cancellationToken = axios.CancelToken.source();
          const {
            data: { exists },
          } = await getGroupPathAvailability(
            importTarget.newName,
            getIdFromGraphQLId(importTarget.targetNamespace.id),
            {
              cancelToken: importTarget.cancellationToken?.token,
            },
          );

          if (exists) {
            newValidationErrors.push({
              field: NEW_NAME_FIELD,
              message: i18n.ERROR_NAME_ALREADY_EXISTS,
            });
          }
        } catch (e) {
          if (!axios.isCancel(e)) {
            throw e;
          }
        }
      }

      // eslint-disable-next-line no-param-reassign
      importTarget.validationErrors = newValidationErrors;
    }, VALIDATION_DEBOUNCE_TIME),

    setDefaultImportTarget(group) {
      if (!this.availableNamespaces) {
        return;
      }

      const lastTargetNamespace = this.availableNamespaces.find(
        (ns) => ns.id === this.defaultTargetNamespace,
      );

      let importTarget;
      if (group.lastImportTarget) {
        const targetNamespace = [ROOT_NAMESPACE, ...this.availableNamespaces].find(
          (ns) => ns.fullPath === group.lastImportTarget.targetNamespace,
        );

        importTarget = {
          targetNamespace: targetNamespace ?? lastTargetNamespace,
          newName: group.lastImportTarget.newName,
        };
      } else {
        importTarget = {
          targetNamespace: lastTargetNamespace,
          newName: group.fullPath,
        };
      }

      const cancellationToken = axios.CancelToken.source();
      this.importTargets = {
        ...this.importTargets,
        [group.id]: {
          ...importTarget,
          cancellationToken,
          validationErrors: [],
        },
      };

      if (!importTarget.targetNamespace) {
        return;
      }

      getGroupPathAvailability(
        importTarget.newName,
        getIdFromGraphQLId(importTarget.targetNamespace.id),
        {
          cancelToken: cancellationToken.token,
        },
      )
        .then(({ data: { exists, suggests: suggestions } }) => {
          if (!exists) return;

          let currentSuggestion = suggestions[0] ?? importTarget.newName;
          const existingTargets = Object.values(this.importTargets)
            .filter((t) => t.targetNamespace.id === importTarget.targetNamespace.id)
            .map((t) => t.newName.toLowerCase());

          while (existingTargets.includes(currentSuggestion.toLowerCase())) {
            currentSuggestion = `${currentSuggestion}-1`;
          }

          Object.assign(this.importTargets[group.id], {
            targetNamespace: importTarget.targetNamespace,
            newName: currentSuggestion,
          });
        })
        .catch(() => {
          // empty catch intended
        });
    },
  },

  PAGE_SIZES,
  permissionsHelpPath: helpPagePath('user/permissions', { anchor: 'group-members-permissions' }),
  betaFeatureHelpPath: helpPagePath('policy/development_stages_support', {
    anchor: 'beta-features',
  }),
  popoverOptions: { title: __('What is listed here?') },
  learnMoreOptions: { title: s__('BulkImport|Import user memberships') },
  i18n,
  LOCAL_STORAGE_KEY: 'gl-bulk-imports-status-page-size-v1',
};
</script>

<template>
  <div>
    <page-heading :heading="s__('BulkImport|Import groups by direct transfer')">
      <template #actions>
        <gl-button
          variant="default"
          category="secondary"
          :href="historyPath"
          data-testid="history-link"
        >
          {{ s__('BulkImport|View import history') }}
        </gl-button>
      </template>
      <template #description
        ><span>{{ s__('BulkImport|Select the groups and projects you want to import.') }}</span>
        <span>
          <gl-sprintf
            :message="
              s__(
                'BulkImport|Please note: importing projects is a %{docsLinkStart}beta%{docsLinkEnd} feature.',
              )
            "
          >
            <template #docsLink="{ content }"
              ><gl-link :href="$options.betaFeatureHelpPath" target="_blank">{{
                content
              }}</gl-link></template
            >
          </gl-sprintf>
        </span></template
      >
    </page-heading>

    <gl-alert
      v-if="unavailableFeatures.length > 0 && unavailableFeaturesAlertVisible"
      data-testid="unavailable-features-alert"
      variant="warning"
      :title="unavailableFeaturesAlertTitle"
      @dismiss="unavailableFeaturesAlertVisible = false"
    >
      <gl-sprintf
        :message="
          s__(
            'BulkImport|Following data will not be migrated: %{bullets} Contact system administrator of %{host} to upgrade GitLab if you need this data in your migration',
          )
        "
      >
        <template #host>
          <gl-link :href="sourceUrl" target="_blank">
            {{ sourceUrl }}<gl-icon name="external-link" class="vertical-align-middle" />
          </gl-link>
        </template>
        <template #bullets>
          <ul>
            <li v-for="feature in unavailableFeatures" :key="feature.title">
              <gl-sprintf :message="s__('BulkImport|%{feature} (require v%{version})')">
                <template #feature>{{ feature.title }}</template>
                <template #version>
                  <strong>{{ feature.version }}</strong>
                </template>
              </gl-sprintf>
            </li>
          </ul>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert variant="warning" :dismissible="false" class="mt-3">
      <gl-sprintf
        :message="
          s__(
            'BulkImport|Be aware of %{linkStart}visibility rules%{linkEnd} when importing groups.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="helpUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <div class="gl-border-0 gl-border-b-1 gl-border-solid gl-border-b-default gl-py-5">
      <gl-search-box-by-click
        class="gl-mb-5"
        data-testid="filter-groups"
        :placeholder="s__('BulkImport|Filter by source group')"
        @submit="filter = $event"
        @clear="filter = ''"
      />
      <span v-if="!$apollo.loading && hasGroups">
        <gl-sprintf :message="statusMessage">
          <template #start>
            <strong>{{ paginationInfo.start }}</strong>
          </template>
          <template #end>
            <strong>{{ paginationInfo.end }}</strong>
          </template>
          <template #total>
            <strong>{{ groupsCount(paginationInfo.total) }}</strong>
          </template>
          <template #filter>
            <strong>{{ filter }}</strong>
          </template>
          <template #link>
            {{ sourceUrl }}
          </template>
        </gl-sprintf>
        <help-popover :options="$options.popoverOptions">
          <gl-sprintf
            :message="
              s__(
                'BulkImport|Only groups that you have the %{role} role for are listed as groups you can import.',
              )
            "
          >
            <template #role>
              <gl-link class="gl-text-sm" :href="$options.permissionsHelpPath" target="_blank">{{
                $options.i18n.OWNER
              }}</gl-link>
            </template>
          </gl-sprintf>
        </help-popover>
      </span>
    </div>
    <gl-loading-icon v-if="$apollo.loading" size="lg" class="gl-mt-5" />
    <template v-else>
      <gl-empty-state
        v-if="hasEmptyFilter"
        :title="__('Sorry, your filter produced no results')"
        :description="__('To widen your search, change or remove filters above.')"
      />
      <gl-empty-state v-else-if="!hasGroups" :title="$options.i18n.NO_GROUPS_FOUND">
        <template #description>
          <gl-sprintf
            :message="__('You don\'t have the %{role} role for any groups in this instance.')"
          >
            <template #role>
              <gl-link :href="$options.permissionsHelpPath" target="_blank">{{
                $options.i18n.OWNER
              }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-empty-state>
      <template v-else>
        <div
          class="import-table-bar gl-sticky gl-z-3 gl-flex-col gl-bg-subtle gl-px-4 md:gl-flex md:gl-flex-row md:gl-items-center md:gl-justify-between"
        >
          <div class="gl-items-center gl-gap-4 gl-py-3 md:gl-flex">
            <span data-test-id="selection-count">
              <gl-sprintf :message="__('%{count} selected')">
                <template #count>
                  {{ selectedGroupsIds.length }}
                </template>
              </gl-sprintf>
            </span>
            <gl-dropdown
              :text="s__('BulkImport|Import with projects')"
              :disabled="!hasSelectedGroups"
              variant="confirm"
              category="primary"
              data-testid="import-selected-groups-dropdown"
              split
              @click="importSelectedGroups({ migrateProjects: true })"
            >
              <gl-dropdown-item @click="importSelectedGroups({ migrateProjects: false })">
                {{ s__('BulkImport|Import without projects') }}
              </gl-dropdown-item>
            </gl-dropdown>
            <span v-if="showImportProjectsWarning" class="gl-shrink-0">
              <gl-icon
                v-gl-tooltip
                :title="s__('BulkImport|Some groups will be imported without projects.')"
                name="warning"
                class="gl-text-orange-500"
                data-testid="import-projects-warning"
              />
            </span>
            <div class="gl-flex gl-items-center">
              <gl-form-checkbox
                v-model="shouldMigrateMemberships"
                data-testid="toggle-import-user-memberships"
                class="gl-mr-2 gl-pt-3"
              >
                {{ s__('BulkImport|Import user memberships') }}
              </gl-form-checkbox>
              <help-popover :options="$options.learnMoreOptions">
                <gl-sprintf
                  :message="
                    s__(
                      'BulkImport|Select whether user memberships in groups and projects are imported.',
                    )
                  "
                />
              </help-popover>
            </div>
          </div>
        </div>
        <gl-table
          ref="table"
          class="import-table gl-w-full"
          :tbody-tr-class="rowClasses"
          :tbody-tr-attr="qaRowAttributes"
          thead-class="gl-sticky gl-z-2 gl-bg-default"
          :items="groupsTableData"
          :fields="$options.fields"
          selectable
          select-mode="multi"
          selected-variant="primary"
          @row-selected="preventSelectingAlreadyImportedGroups"
        >
          <template #head(selected)="{ selectAllRows, clearSelected }">
            <gl-form-checkbox
              :key="`checkbox-${selectedGroupsIds.length}`"
              class="gl-min-h-0"
              :checked="hasSelectedGroups"
              :indeterminate="hasSelectedGroups && !hasAllAvailableGroupsSelected"
              @change="hasAllAvailableGroupsSelected ? clearSelected() : selectAllRows()"
            />
          </template>
          <template #head(importTarget)="data">
            <span data-test-id="new-path-col">
              <span class="gl-mr-2">{{ data.label }}</span
              ><gl-icon
                v-gl-tooltip="s__('BulkImport|Path of the new group.')"
                name="information"
                :size="12"
              />
            </span>
          </template>
          <template #cell(selected)="{ rowSelected, selectRow, unselectRow, item: group }">
            <gl-form-checkbox
              class="gl-h-7 gl-pt-3"
              :checked="rowSelected"
              :disabled="group.flags.isUnselectable"
              @change="rowSelected ? unselectRow() : selectRow()"
            />
          </template>
          <template #cell(webUrl)="{ item: group }">
            <import-source-cell :group="group" />
          </template>
          <template #cell(importTarget)="{ item: group, index }">
            <import-target-cell
              :ref="`importTargetCell-${index}`"
              :group="group"
              :group-path-regex="groupPathRegex"
              @update-target-namespace="updateImportTarget(group, { targetNamespace: $event })"
              @update-new-name="updateImportTarget(group, { newName: $event })"
            />
          </template>
          <template #cell(progress)="{ item: group }">
            <import-status-cell :status="group.visibleStatus" :has-failures="hasFailures(group)" />
            <import-history-link
              v-if="showHistoryLink(group)"
              :id="group.progress.id"
              :history-path="historyShowPath"
              class="gl-mt-2 gl-inline-block"
            />
          </template>
          <template #cell(actions)="{ item: group, index }">
            <import-actions-cell
              :id="group.id"
              :is-finished="group.flags.isFinished"
              :is-available-for-import="group.flags.isAvailableForImport"
              :is-invalid="group.flags.isInvalid"
              :is-project-creation-allowed="group.flags.isProjectCreationAllowed"
              @import-group="importGroup({ group, extraArgs: $event, index })"
            />
          </template>
        </gl-table>
      </template>
    </template>
    <pagination-bar
      v-show="!$apollo.loading && hasGroups"
      :page-info="pageInfo"
      class="gl-mt-3"
      :storage-key="$options.LOCAL_STORAGE_KEY"
      @set-page="setPage"
      @set-page-size="setPageSize"
    />
  </div>
</template>
