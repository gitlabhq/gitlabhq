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
  GlSafeHtmlDirective as SafeHtml,
  GlTable,
  GlTooltip,
} from '@gitlab/ui';
import { s__, __, n__ } from '~/locale';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import ImportStatus from '../../components/import_status.vue';
import { STATUSES } from '../../constants';
import importGroupsMutation from '../graphql/mutations/import_groups.mutation.graphql';
import setImportTargetMutation from '../graphql/mutations/set_import_target.mutation.graphql';
import availableNamespacesQuery from '../graphql/queries/available_namespaces.query.graphql';
import bulkImportSourceGroupsQuery from '../graphql/queries/bulk_import_source_groups.query.graphql';
import { isInvalid } from '../utils';
import ImportTargetCell from './import_target_cell.vue';

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
    GlSprintf,
    GlTooltip,
    GlTable,
    ImportStatus,
    ImportTargetCell,
    PaginationLinks,
  },
  directives: {
    SafeHtml,
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
    groupUrlErrorMessage: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      filter: '',
      page: 1,
      perPage: DEFAULT_PAGE_SIZE,
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
      key: 'web_url',
      label: s__('BulkImport|From source group'),
      thClass: `${DEFAULT_TH_CLASSES} import-jobs-from-col`,
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'import_target',
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

    hasGroupsWithValidationError() {
      return this.groups.some((g) => g.validation_errors.length);
    },

    availableGroupsForImport() {
      return this.groups.filter((g) => g.progress.status === STATUSES.NONE);
    },

    isImportAllButtonDisabled() {
      return this.hasGroupsWithValidationError || this.availableGroupsForImport.length === 0;
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
      const end = start + (this.bulkImportSourceGroups.nodes?.length ?? 0) - 1;

      return { start, end, total };
    },
  },

  watch: {
    filter() {
      this.page = 1;
    },
  },

  methods: {
    qaRowAttributes(group, type) {
      if (type === 'row') {
        return {
          'data-qa-selector': 'import_item',
          'data-qa-source-group': group.full_path,
        };
      }

      return {};
    },

    isAlreadyImported(group) {
      return group.progress.status !== STATUSES.NONE;
    },

    isInvalid(group) {
      return isInvalid(group, this.groupPathRegex);
    },

    groupsCount(count) {
      return n__('%d group', '%d groups', count);
    },

    setPage(page) {
      this.page = page;
    },

    updateImportTarget(sourceGroupId, targetNamespace, newName) {
      this.$apollo.mutate({
        mutation: setImportTargetMutation,
        variables: { sourceGroupId, targetNamespace, newName },
      });
    },

    importGroups(sourceGroupIds) {
      this.$apollo.mutate({
        mutation: importGroupsMutation,
        variables: { sourceGroupIds },
      });
    },

    importAllGroups() {
      this.importGroups(this.availableGroupsForImport.map((g) => g.id));
    },

    setPageSize(size) {
      this.perPage = size;
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
      <div ref="importAllButtonWrapper" class="gl-ml-auto">
        <gl-button
          v-if="!$apollo.loading && hasGroups"
          :disabled="isImportAllButtonDisabled"
          variant="confirm"
          @click="importAllGroups"
        >
          <gl-sprintf :message="s__('BulkImport|Import %{groups}')">
            <template #groups>
              {{ groupsCount(availableGroupsForImport.length) }}
            </template>
          </gl-sprintf>
        </gl-button>
      </div>
      <gl-tooltip v-if="isImportAllButtonDisabled" :target="() => $refs.importAllButtonWrapper">
        <template v-if="hasGroupsWithValidationError">
          {{ s__('BulkImport|One or more groups has validation errors') }}
        </template>
        <template v-else>
          {{ s__('BulkImport|No groups on this page are available for import') }}
        </template>
      </gl-tooltip>
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
            <gl-link class="gl-display-inline-block" :href="sourceUrl" target="_blank">
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
        :description="s__('Check your source instance permissions.')"
      />
      <template v-else>
        <gl-table
          class="gl-w-full"
          data-qa-selector="import_table"
          tbody-tr-class="gl-border-gray-200 gl-border-0 gl-border-b-1 gl-border-solid"
          :tbody-tr-attr="qaRowAttributes"
          :items="bulkImportSourceGroups.nodes"
          :fields="$options.fields"
        >
          <template #cell(web_url)="{ value: web_url, item: { full_path } }">
            <gl-link
              :href="web_url"
              target="_blank"
              class="gl-display-flex gl-align-items-center gl-h-7"
            >
              {{ full_path }} <gl-icon name="external-link" />
            </gl-link>
          </template>
          <template #cell(import_target)="{ item: group }">
            <import-target-cell
              :group="group"
              :available-namespaces="availableNamespaces"
              :group-path-regex="groupPathRegex"
              :group-url-error-message="groupUrlErrorMessage"
              @update-target-namespace="
                updateImportTarget(group.id, $event, group.import_target.new_name)
              "
              @update-new-name="
                updateImportTarget(group.id, group.import_target.target_namespace, $event)
              "
            />
          </template>
          <template #cell(progress)="{ value: { status } }">
            <import-status :status="status" class="gl-mt-2" />
          </template>
          <template #cell(actions)="{ item: group }">
            <gl-button
              v-if="!isAlreadyImported(group)"
              :disabled="isInvalid(group)"
              variant="confirm"
              category="secondary"
              data-qa-selector="import_group_button"
              @click="importGroups([group.id])"
            >
              {{ __('Import') }}
            </gl-button>
          </template>
        </gl-table>
        <div v-if="hasGroups" class="gl-display-flex gl-mt-3 gl-align-items-center">
          <pagination-links
            :change="setPage"
            :page-info="bulkImportSourceGroups.pageInfo"
            class="gl-m-0"
          />
          <gl-dropdown category="tertiary" class="gl-ml-auto">
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
