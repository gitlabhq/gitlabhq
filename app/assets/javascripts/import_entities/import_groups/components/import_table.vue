<script>
import {
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSearchBoxByClick,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import bulkImportSourceGroupsQuery from '../graphql/queries/bulk_import_source_groups.query.graphql';
import availableNamespacesQuery from '../graphql/queries/available_namespaces.query.graphql';
import setTargetNamespaceMutation from '../graphql/mutations/set_target_namespace.mutation.graphql';
import setNewNameMutation from '../graphql/mutations/set_new_name.mutation.graphql';
import importGroupMutation from '../graphql/mutations/import_group.mutation.graphql';
import ImportTableRow from './import_table_row.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';

export default {
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSearchBoxByClick,
    GlSprintf,
    ImportTableRow,
    PaginationLinks,
  },

  props: {
    sourceUrl: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      filter: '',
      page: 1,
    };
  },

  apollo: {
    bulkImportSourceGroups: {
      query: bulkImportSourceGroupsQuery,
      variables() {
        return { page: this.page, filter: this.filter };
      },
    },
    availableNamespaces: availableNamespacesQuery,
  },

  computed: {
    hasGroups() {
      return this.bulkImportSourceGroups?.nodes?.length > 0;
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
    setPage(page) {
      this.page = page;
    },

    updateTargetNamespace(sourceGroupId, targetNamespace) {
      this.$apollo.mutate({
        mutation: setTargetNamespaceMutation,
        variables: { sourceGroupId, targetNamespace },
      });
    },

    updateNewName(sourceGroupId, newName) {
      this.$apollo.mutate({
        mutation: setNewNameMutation,
        variables: { sourceGroupId, newName },
      });
    },

    importGroup(sourceGroupId) {
      this.$apollo.mutate({
        mutation: importGroupMutation,
        variables: { sourceGroupId },
      });
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-py-5 gl-border-solid gl-border-gray-200 gl-border-0 gl-border-b-1 gl-display-flex gl-align-items-center"
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
            <strong>{{ n__('%d group', '%d groups', paginationInfo.total) }}</strong>
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
      <gl-search-box-by-click class="gl-ml-auto" @submit="filter = $event" @clear="filter = ''" />
    </div>
    <gl-loading-icon v-if="$apollo.loading" size="md" class="gl-mt-5" />
    <template v-else>
      <gl-empty-state v-if="hasEmptyFilter" :title="__('Sorry, your filter produced no results')" />
      <gl-empty-state
        v-else-if="!hasGroups"
        :title="s__('BulkImport|No groups available for import')"
      />
      <div v-else class="gl-display-flex gl-flex-direction-column gl-align-items-center">
        <table class="gl-w-full">
          <thead class="gl-border-solid gl-border-gray-200 gl-border-0 gl-border-b-1">
            <th class="gl-py-4 import-jobs-from-col">{{ s__('BulkImport|From source group') }}</th>
            <th class="gl-py-4 import-jobs-to-col">{{ s__('BulkImport|To new group') }}</th>
            <th class="gl-py-4 import-jobs-status-col">{{ __('Status') }}</th>
            <th class="gl-py-4 import-jobs-cta-col"></th>
          </thead>
          <tbody>
            <template v-for="group in bulkImportSourceGroups.nodes">
              <import-table-row
                :key="group.id"
                :group="group"
                :available-namespaces="availableNamespaces"
                @update-target-namespace="updateTargetNamespace(group.id, $event)"
                @update-new-name="updateNewName(group.id, $event)"
                @import-group="importGroup(group.id)"
              />
            </template>
          </tbody>
        </table>
        <pagination-links
          :change="setPage"
          :page-info="bulkImportSourceGroups.pageInfo"
          class="gl-mt-3"
        />
      </div>
    </template>
  </div>
</template>
