<script>
import { GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import {
  bodyTrClass,
  initialPaginationState,
} from '~/vue_shared/components/paginated_table_with_search_and_tabs/constants';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { EDIT_ROUTE_NAME, NEW_ROUTE_NAME, organizationTrackViewsOptions } from '../../constants';
import getGroupOrganizationsQuery from './graphql/get_group_organizations.query.graphql';
import getGroupOrganizationsCountByStateQuery from './graphql/get_group_organizations_count_by_state.query.graphql';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    GlTable,
    PaginatedTableWithSearchAndTabs,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'canAdminCrmOrganization',
    'canReadCrmContact',
    'groupContactsPath',
    'groupFullPath',
    'groupIssuesPath',
    'textQuery',
  ],
  data() {
    return {
      organizations: { list: [] },
      organizationsCount: {},
      error: false,
      filteredByStatus: '',
      pagination: initialPaginationState,
      statusFilter: 'all',
      searchTerm: this.textQuery,
      sort: 'NAME_ASC',
      sortDesc: false,
    };
  },
  apollo: {
    organizations: {
      query: getGroupOrganizationsQuery,
      variables() {
        return {
          groupFullPath: this.groupFullPath,
          searchTerm: this.searchTerm,
          state: this.statusFilter,
          sort: this.sort,
          firstPageSize: this.pagination.firstPageSize,
          lastPageSize: this.pagination.lastPageSize,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
        };
      },
      update(data) {
        return this.extractOrganizations(data);
      },
      error() {
        this.error = true;
      },
    },
    organizationsCount: {
      query: getGroupOrganizationsCountByStateQuery,
      variables() {
        return {
          groupFullPath: this.groupFullPath,
          searchTerm: this.searchTerm,
        };
      },
      update(data) {
        return data?.group?.organizationStateCounts;
      },
      error() {
        this.error = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.organizations.loading;
    },
    tbodyTrClass() {
      return {
        [bodyTrClass]: !this.isLoading && !this.isEmpty,
      };
    },
  },
  methods: {
    errorAlertDismissed() {
      this.error = false;
    },
    extractOrganizations(data) {
      const organizations = data?.group?.organizations?.nodes || [];
      const pageInfo = data?.group?.organizations?.pageInfo || {};
      return {
        list: organizations,
        pageInfo,
      };
    },
    fetchSortedData({ sortBy, sortDesc }) {
      const sortingColumn = convertToSnakeCase(sortBy).toUpperCase();
      const sortingDirection = sortDesc ? 'DESC' : 'ASC';
      this.pagination = initialPaginationState;
      this.sort = `${sortingColumn}_${sortingDirection}`;
    },
    filtersChanged({ searchTerm }) {
      this.searchTerm = searchTerm;
    },
    getIssuesPath(path, value) {
      return `${path}?crm_organization_id=${value}`;
    },
    getEditRoute(id) {
      return { name: this.$options.EDIT_ROUTE_NAME, params: { id } };
    },
    pageChanged(pagination) {
      this.pagination = pagination;
    },
    statusChanged({ filters, status }) {
      this.statusFilter = filters;
      this.filteredByStatus = status;
    },
  },
  fields: [
    { key: 'name', sortable: true },
    { key: 'defaultRate', sortable: true },
    { key: 'description', sortable: true },
    {
      key: 'id',
      label: '',
      formatter: (id) => {
        return getIdFromGraphQLId(id);
      },
    },
  ],
  i18n: {
    emptyText: s__('Crm|No organizations found'),
    issuesButtonLabel: __('View issues'),
    editButtonLabel: __('Edit'),
    title: s__('Crm|Customer relations organizations'),
    newOrganization: s__('Crm|New organization'),
    errorMsg: __('Something went wrong. Please try again.'),
    contacts: s__('Crm|Contacts'),
  },
  EDIT_ROUTE_NAME,
  NEW_ROUTE_NAME,
  statusTabs: [
    {
      title: __('Active'),
      status: 'ACTIVE',
      filters: 'active',
    },
    {
      title: __('Inactive'),
      status: 'INACTIVE',
      filters: 'inactive',
    },
    {
      title: __('All'),
      status: 'ALL',
      filters: 'all',
    },
  ],
  organizationTrackViewsOptions,
  emptyArray: [],
};
</script>

<template>
  <div>
    <paginated-table-with-search-and-tabs
      :show-items="true"
      :show-error-msg="error"
      :i18n="$options.i18n"
      :items="organizations.list"
      :page-info="organizations.pageInfo"
      :items-count="organizationsCount"
      :status-tabs="$options.statusTabs"
      :track-views-options="$options.organizationTrackViewsOptions"
      :filter-search-tokens="$options.emptyArray"
      filter-search-key="organizations"
      @page-changed="pageChanged"
      @tabs-changed="statusChanged"
      @filters-changed="filtersChanged"
      @error-alert-dismissed="errorAlertDismissed"
    >
      <template #header-actions>
        <div class="gl-my-3 gl-mr-5 gl-flex gl-items-center gl-justify-end">
          <a
            v-if="canReadCrmContact"
            :href="groupContactsPath"
            class="gl-mr-3"
            data-testid="contacts-link"
            >{{ $options.i18n.contacts }}</a
          >
          <router-link v-if="canAdminCrmOrganization" :to="{ name: $options.NEW_ROUTE_NAME }">
            <gl-button variant="confirm" data-testid="new-organization-button">
              {{ $options.i18n.newOrganization }}
            </gl-button>
          </router-link>
        </div>
      </template>

      <template #title>
        {{ $options.i18n.title }}
      </template>

      <template #table>
        <gl-table
          :items="organizations.list"
          :fields="$options.fields"
          :busy="isLoading"
          stacked="md"
          :tbody-tr-class="tbodyTrClass"
          sort-direction="asc"
          :sort-desc.sync="sortDesc"
          sort-by="createdAt"
          show-empty
          no-local-sorting
          fixed
          @sort-changed="fetchSortedData"
        >
          <template #cell(id)="{ value: id }">
            <gl-button
              v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
              class="gl-mr-3"
              data-testid="issues-link"
              icon="issues"
              :aria-label="$options.i18n.issuesButtonLabel"
              :href="getIssuesPath(groupIssuesPath, id)"
            />
            <router-link :to="getEditRoute(id)">
              <gl-button
                v-if="canAdminCrmOrganization"
                v-gl-tooltip.hover.bottom="$options.i18n.editButtonLabel"
                icon="pencil"
                :aria-label="$options.i18n.editButtonLabel"
              />
            </router-link>
          </template>

          <template #table-busy>
            <gl-loading-icon size="lg" color="dark" class="mt-3" />
          </template>

          <template #empty>
            <span>
              {{ $options.i18n.emptyText }}
            </span>
          </template>
        </gl-table>
      </template>
    </paginated-table-with-search-and-tabs>
    <router-view />
  </div>
</template>
