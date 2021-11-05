<script>
import {
  GlButton,
  GlEmptyState,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSearchBoxByClick,
  GlSprintf,
  GlTable,
  GlFormCheckbox,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import { s__, __, n__ } from '~/locale';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { getGroupPathAvailability } from '~/rest_api';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import { STATUSES } from '../../constants';
import ImportStatusCell from '../../components/import_status.vue';
import importGroupsMutation from '../graphql/mutations/import_groups.mutation.graphql';
import updateImportStatusMutation from '../graphql/mutations/update_import_status.mutation.graphql';
import availableNamespacesQuery from '../graphql/queries/available_namespaces.query.graphql';
import bulkImportSourceGroupsQuery from '../graphql/queries/bulk_import_source_groups.query.graphql';
import { NEW_NAME_FIELD, i18n } from '../constants';
import { StatusPoller } from '../services/status_poller';
import { isFinished, isAvailableForImport, isNameValid, isSameTarget } from '../utils';
import ImportActionsCell from './import_actions_cell.vue';
import ImportSourceCell from './import_source_cell.vue';
import ImportTargetCell from './import_target_cell.vue';

const VALIDATION_DEBOUNCE_TIME = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;
const PAGE_SIZES = [20, 50, 100];
const DEFAULT_PAGE_SIZE = PAGE_SIZES[0];
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-200! gl-border-b-1! gl-p-5!';
const DEFAULT_TD_CLASSES = 'gl-vertical-align-top!';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlDropdown,
    GlDropdownItem,
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
    PaginationLinks,
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
  },

  data() {
    return {
      filter: '',
      page: 1,
      perPage: DEFAULT_PAGE_SIZE,
      selectedGroupsIds: [],
      pendingGroupsIds: [],
      importTargets: {},
    };
  },

  apollo: {
    bulkImportSourceGroups: {
      query: bulkImportSourceGroupsQuery,
      variables() {
        return { page: this.page, filter: this.filter, perPage: this.perPage };
      },
    },
    availableNamespaces: availableNamespacesQuery,
  },

  fields: [
    {
      key: 'selected',
      label: '',
      // eslint-disable-next-line @gitlab/require-i18n-strings
      thClass: `${DEFAULT_TH_CLASSES} gl-w-3 gl-pr-3!`,
      // eslint-disable-next-line @gitlab/require-i18n-strings
      tdClass: `${DEFAULT_TD_CLASSES} gl-pr-3!`,
    },
    {
      key: 'webUrl',
      label: s__('BulkImport|From source group'),
      thClass: `${DEFAULT_TH_CLASSES} gl-pl-0! import-jobs-from-col`,
      // eslint-disable-next-line @gitlab/require-i18n-strings
      tdClass: `${DEFAULT_TD_CLASSES} gl-pl-0!`,
    },
    {
      key: 'importTarget',
      label: s__('BulkImport|To new group'),
      thClass: `${DEFAULT_TH_CLASSES} import-jobs-to-col`,
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'progress',
      label: __('Status'),
      thClass: `${DEFAULT_TH_CLASSES} import-jobs-status-col`,
      tdClass: DEFAULT_TD_CLASSES,
      tdAttr: { 'data-qa-selector': 'import_status_indicator' },
    },
    {
      key: 'actions',
      label: '',
      thClass: `${DEFAULT_TH_CLASSES} import-jobs-cta-col`,
      tdClass: DEFAULT_TD_CLASSES,
    },
  ],

  computed: {
    groups() {
      return this.bulkImportSourceGroups?.nodes ?? [];
    },

    groupsTableData() {
      return this.groups.map((group) => {
        const importTarget = this.getImportTarget(group);
        const status = this.getStatus(group);

        const flags = {
          isInvalid: importTarget.validationErrors?.length > 0,
          isAvailableForImport: isAvailableForImport(group) && status !== STATUSES.SCHEDULING,
          isFinished: isFinished(group),
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

    availableGroupsForImport() {
      return this.groupsTableData.filter((g) => g.flags.isAvailableForImport && g.flags.isInvalid);
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
        ? s__('BulkImport|Showing %{start}-%{end} of %{total} from %{link}')
        : s__(
            'BulkImport|Showing %{start}-%{end} of %{total} matching filter "%{filter}" from %{link}',
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
  },

  watch: {
    filter() {
      this.page = 1;
    },

    groupsTableData() {
      const table = this.getTableRef();
      const matches = new Set();
      this.groupsTableData.forEach((g, idx) => {
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
        this.$apollo.mutate({
          mutation: updateImportStatusMutation,
          variables: { id: update.id, status: update.status_name },
        });
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
        'gl-border-gray-200',
        'gl-border-0',
        'gl-border-b-1',
        'gl-border-solid',
      ];
      const result = [...DEFAULT_CLASSES];
      if (groupTableItem.flags.isUnselectable) {
        result.push('gl-cursor-default!');
      }
      return result;
    },

    qaRowAttributes(group, type) {
      if (type === 'row') {
        return {
          'data-qa-selector': 'import_item',
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

    updateImportTarget(group, changes) {
      const newImportTarget = {
        ...group.importTarget,
        ...changes,
      };
      this.$set(this.importTargets, group.id, newImportTarget);
      this.validateImportTarget(newImportTarget);
    },

    async importGroups(importRequests) {
      const newPendingGroupsIds = importRequests.map((request) => request.sourceGroupId);
      newPendingGroupsIds.forEach((id) => {
        this.importTargets[id].validationErrors = [
          { field: NEW_NAME_FIELD, message: i18n.ERROR_IMPORT_COMPLETED },
        ];

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
        const message = error?.networkError?.response?.data?.error ?? i18n.ERROR_IMPORT;
        createFlash({
          message,
          captureError: true,
          error,
        });
      } finally {
        this.pendingGroupsIds = this.pendingGroupsIds.filter(
          (id) => !newPendingGroupsIds.includes(id),
        );
      }
    },

    importSelectedGroups() {
      const importRequests = this.groupsTableData
        .filter((group) => this.selectedGroupsIds.includes(group.id))
        .map((group) => ({
          sourceGroupId: group.id,
          targetNamespace: group.importTarget.targetNamespace.fullPath,
          newName: group.importTarget.newName,
        }));

      this.importGroups(importRequests);
    },

    setPageSize(size) {
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

    validateImportTarget: debounce(async function validate(importTarget) {
      const newValidationErrors = [];
      importTarget.cancellationToken?.cancel();
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
            importTarget.targetNamespace.id,
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

    getImportTarget(group) {
      if (this.importTargets[group.id]) {
        return this.importTargets[group.id];
      }

      const defaultTargetNamespace = this.availableNamespaces[0] ?? { fullPath: '', id: null };
      let importTarget;
      if (group.lastImportTarget) {
        const targetNamespace = this.availableNamespaces.find(
          (ns) => ns.fullPath === group.lastImportTarget.targetNamespace,
        );

        importTarget = {
          targetNamespace: targetNamespace ?? defaultTargetNamespace,
          newName: group.lastImportTarget.newName,
        };
      } else {
        importTarget = {
          targetNamespace: defaultTargetNamespace,
          newName: group.fullPath,
        };
      }

      const cancellationToken = axios.CancelToken.source();
      this.$set(this.importTargets, group.id, {
        ...importTarget,
        cancellationToken,
        validationErrors: [],
      });

      getGroupPathAvailability(importTarget.newName, importTarget.targetNamespace.id, {
        cancelToken: cancellationToken.token,
      })
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
      return this.importTargets[group.id];
    },
  },

  gitlabLogo: window.gon.gitlab_logo,
  PAGE_SIZES,
};
</script>

<template>
  <div>
    <h1
      class="gl-my-0 gl-py-4 gl-font-size-h1 gl-border-solid gl-border-gray-200 gl-border-0 gl-border-b-1 gl-display-flex"
    >
      <img :src="$options.gitlabLogo" class="gl-w-6 gl-h-6 gl-mb-2 gl-display-inline gl-mr-2" />
      {{ s__('BulkImport|Import groups from GitLab') }}
    </h1>
    <div
      class="gl-py-5 gl-border-solid gl-border-gray-200 gl-border-0 gl-border-b-1 gl-display-flex"
    >
      <span>
        <gl-sprintf v-if="!$apollo.loading && hasGroups" :message="statusMessage">
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
            <gl-link :href="sourceUrl" target="_blank">
              {{ sourceUrl }} <gl-icon name="external-link" class="vertical-align-middle" />
            </gl-link>
          </template>
        </gl-sprintf>
      </span>
      <gl-search-box-by-click
        class="gl-ml-auto"
        :placeholder="s__('BulkImport|Filter by source group')"
        @submit="filter = $event"
        @clear="filter = ''"
      />
    </div>
    <gl-loading-icon v-if="$apollo.loading" size="md" class="gl-mt-5" />
    <template v-else>
      <gl-empty-state
        v-if="hasEmptyFilter"
        :title="__('Sorry, your filter produced no results')"
        :description="__('To widen your search, change or remove filters above.')"
      />
      <gl-empty-state
        v-else-if="!hasGroups"
        :title="s__('BulkImport|You have no groups to import')"
        :description="__('Check your source instance permissions.')"
      />
      <template v-else>
        <div
          class="gl-bg-gray-10 gl-border-solid gl-border-gray-200 gl-border-0 gl-border-b-1 gl-p-4 gl-display-flex gl-align-items-center"
        >
          <gl-sprintf :message="__('%{count} selected')">
            <template #count>
              {{ selectedGroupsIds.length }}
            </template>
          </gl-sprintf>
          <gl-button
            category="primary"
            variant="confirm"
            class="gl-ml-4"
            :disabled="!hasSelectedGroups"
            @click="importSelectedGroups"
            >{{ s__('BulkImport|Import selected') }}</gl-button
          >
        </div>
        <gl-table
          ref="table"
          class="gl-w-full"
          data-qa-selector="import_table"
          :tbody-tr-class="rowClasses"
          :tbody-tr-attr="qaRowAttributes"
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
              class="gl-h-7 gl-pt-3"
              :checked="hasSelectedGroups"
              :indeterminate="hasSelectedGroups && !hasAllAvailableGroupsSelected"
              @change="hasAllAvailableGroupsSelected ? clearSelected() : selectAllRows()"
            />
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
          <template #cell(importTarget)="{ item: group }">
            <import-target-cell
              :group="group"
              :available-namespaces="availableNamespaces"
              :group-path-regex="groupPathRegex"
              @update-target-namespace="updateImportTarget(group, { targetNamespace: $event })"
              @update-new-name="updateImportTarget(group, { newName: $event })"
            />
          </template>
          <template #cell(progress)="{ item: group }">
            <import-status-cell :status="group.visibleStatus" class="gl-line-height-32" />
          </template>
          <template #cell(actions)="{ item: group }">
            <import-actions-cell
              :is-finished="group.flags.isFinished"
              :is-available-for-import="group.flags.isAvailableForImport"
              :is-invalid="group.flags.isInvalid"
              @import-group="
                importGroups([
                  {
                    sourceGroupId: group.id,
                    targetNamespace: group.importTarget.targetNamespace.fullPath,
                    newName: group.importTarget.newName,
                  },
                ])
              "
            />
          </template>
        </gl-table>
        <div v-if="hasGroups" class="gl-display-flex gl-mt-3 gl-align-items-center">
          <pagination-links
            :change="setPage"
            :page-info="bulkImportSourceGroups.pageInfo"
            class="gl-m-0"
          />
          <gl-dropdown category="tertiary" :aria-label="__('Page size')" class="gl-ml-auto">
            <template #button-content>
              <span class="font-weight-bold">
                <gl-sprintf :message="__('%{count} items per page')">
                  <template #count>
                    {{ perPage }}
                  </template>
                </gl-sprintf>
              </span>
              <gl-icon class="gl-button-icon dropdown-chevron" name="chevron-down" />
            </template>
            <gl-dropdown-item
              v-for="size in $options.PAGE_SIZES"
              :key="size"
              @click="setPageSize(size)"
            >
              <gl-sprintf :message="__('%{count} items per page')">
                <template #count>
                  {{ size }}
                </template>
              </gl-sprintf>
            </gl-dropdown-item>
          </gl-dropdown>
          <div class="gl-ml-2">
            <gl-sprintf :message="s__('BulkImport|Showing %{start}-%{end} of %{total}')">
              <template #start>
                {{ paginationInfo.start }}
              </template>
              <template #end>
                {{ paginationInfo.end }}
              </template>
              <template #total>
                {{ humanizedTotal }}
              </template>
            </gl-sprintf>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>
