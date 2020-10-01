<script>
import {
  GlLoadingIcon,
  GlTable,
  GlAlert,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlTooltipDirective,
  GlButton,
  GlIcon,
  GlPagination,
  GlTabs,
  GlTab,
  GlBadge,
  GlEmptyState,
} from '@gitlab/ui';
import Api from '~/api';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { s__, __ } from '~/locale';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import {
  visitUrl,
  mergeUrlParams,
  joinPaths,
  updateHistory,
  setUrlParams,
} from '~/lib/utils/url_utility';
import getIncidents from '../graphql/queries/get_incidents.query.graphql';
import getIncidentsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import { INCIDENT_SEVERITY } from '~/sidebar/components/severity/constants';
import {
  I18N,
  DEFAULT_PAGE_SIZE,
  INCIDENT_STATUS_TABS,
  TH_CREATED_AT_TEST_ID,
  TH_SEVERITY_TEST_ID,
  TH_PUBLISHED_TEST_ID,
  INCIDENT_DETAILS_PATH,
} from '../constants';

const tdClass =
  'table-col gl-display-flex d-md-table-cell gl-align-items-center gl-white-space-nowrap';
const thClass = 'gl-hover-bg-blue-50';
const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 gl-hover-cursor-pointer gl-hover-bg-blue-50 gl-hover-border-b-solid gl-hover-border-blue-200';

const initialPaginationState = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: DEFAULT_PAGE_SIZE,
  lastPageSize: null,
};

export default {
  i18n: I18N,
  statusTabs: INCIDENT_STATUS_TABS,
  fields: [
    {
      key: 'severity',
      label: s__('IncidentManagement|Severity'),
      thClass,
      tdClass: `${tdClass} sortable-cell`,
      sortable: true,
      thAttr: TH_SEVERITY_TEST_ID,
    },
    {
      key: 'title',
      label: s__('IncidentManagement|Incident'),
      thClass: `gl-pointer-events-none gl-w-half`,
      tdClass,
    },
    {
      key: 'createdAt',
      label: s__('IncidentManagement|Date created'),
      thClass,
      tdClass: `${tdClass} sortable-cell`,
      sortable: true,
      thAttr: TH_CREATED_AT_TEST_ID,
    },
    {
      key: 'assignees',
      label: s__('IncidentManagement|Assignees'),
      thClass: 'gl-pointer-events-none',
      tdClass,
    },
  ],
  components: {
    GlLoadingIcon,
    GlTable,
    GlAlert,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
    GlButton,
    TimeAgoTooltip,
    GlIcon,
    GlPagination,
    GlTabs,
    GlTab,
    PublishedCell: () => import('ee_component/incidents/components/published_cell.vue'),
    GlBadge,
    GlEmptyState,
    SeverityToken,
    FilteredSearchBar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'projectPath',
    'newIssuePath',
    'incidentTemplateName',
    'incidentType',
    'issuePath',
    'publishedAvailable',
    'emptyListSvgPath',
    'textQuery',
    'authorUsernamesQuery',
    'assigneeUsernamesQuery',
  ],
  apollo: {
    incidents: {
      query: getIncidents,
      variables() {
        return {
          searchTerm: this.searchTerm,
          status: this.statusFilter,
          projectPath: this.projectPath,
          issueTypes: ['INCIDENT'],
          sort: this.sort,
          firstPageSize: this.pagination.firstPageSize,
          lastPageSize: this.pagination.lastPageSize,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
          authorUsername: this.authorUsername,
          assigneeUsernames: this.assigneeUsernames,
        };
      },
      update({ project: { issues: { nodes = [], pageInfo = {} } = {} } = {} }) {
        return {
          list: nodes,
          pageInfo,
        };
      },
      error() {
        this.errored = true;
      },
    },
    incidentsCount: {
      query: getIncidentsCountByStatus,
      variables() {
        return {
          searchTerm: this.searchTerm,
          authorUsername: this.authorUsername,
          assigneeUsernames: this.assigneeUsernames,
          projectPath: this.projectPath,
          issueTypes: ['INCIDENT'],
        };
      },
      update(data) {
        return data.project?.issueStatusCounts;
      },
    },
  },
  data() {
    return {
      errored: false,
      isErrorAlertDismissed: false,
      redirecting: false,
      searchTerm: this.textQuery,
      pagination: initialPaginationState,
      incidents: {},
      sort: 'created_desc',
      sortBy: 'createdAt',
      sortDesc: true,
      statusFilter: '',
      filteredByStatus: '',
      authorUsername: this.authorUsernamesQuery,
      assigneeUsernames: this.assigneeUsernamesQuery,
      filterParams: {},
    };
  },
  computed: {
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed;
    },
    loading() {
      return this.$apollo.queries.incidents.loading;
    },
    hasIncidents() {
      return this.incidents?.list?.length;
    },
    incidentsForCurrentTab() {
      return this.incidentsCount?.[this.filteredByStatus.toLowerCase()] ?? 0;
    },
    showPaginationControls() {
      return Boolean(
        this.incidents?.pageInfo?.hasNextPage || this.incidents?.pageInfo?.hasPreviousPage,
      );
    },
    prevPage() {
      return Math.max(this.pagination.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.pagination.currentPage + 1;
      return nextPage > Math.ceil(this.incidentsForCurrentTab / DEFAULT_PAGE_SIZE)
        ? null
        : nextPage;
    },
    tbodyTrClass() {
      return {
        [bodyTrClass]: !this.loading && this.hasIncidents,
      };
    },
    newIncidentPath() {
      return mergeUrlParams(
        {
          issuable_template: this.incidentTemplateName,
          'issue[issue_type]': this.incidentType,
        },
        this.newIssuePath,
      );
    },
    availableFields() {
      return this.publishedAvailable
        ? [
            ...this.$options.fields,
            ...[
              {
                key: 'published',
                label: s__('IncidentManagement|Published'),
                thClass,
                tdClass: `${tdClass} sortable-cell`,
                sortable: true,
                thAttr: TH_PUBLISHED_TEST_ID,
              },
            ],
          ]
        : this.$options.fields;
    },
    isEmpty() {
      return !this.incidents.list?.length;
    },
    showList() {
      return !this.isEmpty || this.errored || this.loading;
    },
    activeClosedTabHasNoIncidents() {
      const { all, closed } = this.incidentsCount || {};
      const isClosedTabActive = this.statusFilter === this.$options.statusTabs[1].filters;

      return isClosedTabActive && all && !closed;
    },
    emptyStateData() {
      const {
        emptyState: { title, emptyClosedTabTitle, description },
        createIncidentBtnLabel,
      } = this.$options.i18n;

      if (this.activeClosedTabHasNoIncidents) {
        return { title: emptyClosedTabTitle };
      }
      return {
        title,
        description,
        btnLink: this.newIncidentPath,
        btnText: createIncidentBtnLabel,
      };
    },
    filteredSearchTokens() {
      return [
        {
          type: 'author_username',
          icon: 'user',
          title: __('Author'),
          unique: true,
          symbol: '@',
          token: AuthorToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
          fetchPath: this.projectPath,
          fetchAuthors: Api.projectUsers.bind(Api),
        },
        {
          type: 'assignee_username',
          icon: 'user',
          title: __('Assignees'),
          unique: true,
          symbol: '@',
          token: AuthorToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
          fetchPath: this.projectPath,
          fetchAuthors: Api.projectUsers.bind(Api),
        },
      ];
    },
    filteredSearchValue() {
      const value = [];

      if (this.authorUsername) {
        value.push({
          type: 'author_username',
          value: { data: this.authorUsername },
        });
      }

      if (this.assigneeUsernames) {
        value.push({
          type: 'assignee_username',
          value: { data: this.assigneeUsernames },
        });
      }

      if (this.searchTerm) {
        value.push(this.searchTerm);
      }

      return value;
    },
  },
  methods: {
    filterIncidentsByStatus(tabIndex) {
      this.resetPagination();
      const { filters, status } = this.$options.statusTabs[tabIndex];
      this.statusFilter = filters;
      this.filteredByStatus = status;
    },
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    navigateToIncidentDetails({ iid }) {
      const path = this.glFeatures.issuesIncidentDetails
        ? joinPaths(this.issuePath, INCIDENT_DETAILS_PATH)
        : this.issuePath;
      return visitUrl(joinPaths(path, iid));
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.incidents.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          ...initialPaginationState,
          nextPageCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          lastPageSize: DEFAULT_PAGE_SIZE,
          firstPageSize: null,
          prevPageCursor: startCursor,
          nextPageCursor: '',
          currentPage: page,
        };
      }
    },
    resetPagination() {
      this.pagination = initialPaginationState;
    },
    fetchSortedData({ sortBy, sortDesc }) {
      const sortingDirection = sortDesc ? 'DESC' : 'ASC';
      const sortingColumn = convertToSnakeCase(sortBy)
        .replace(/_.*/, '')
        .toUpperCase();

      this.resetPagination();
      this.sort = `${sortingColumn}_${sortingDirection}`;
    },
    getSeverity(severity) {
      return INCIDENT_SEVERITY[severity];
    },
    handleFilterIncidents(filters) {
      this.resetPagination();
      const filterParams = { authorUsername: '', assigneeUsername: '', search: '' };

      filters.forEach(filter => {
        if (typeof filter === 'object') {
          switch (filter.type) {
            case 'author_username':
              filterParams.authorUsername = filter.value.data;
              break;
            case 'assignee_username':
              filterParams.assigneeUsername = filter.value.data;
              break;
            case 'filtered-search-term':
              if (filter.value.data !== '') filterParams.search = filter.value.data;
              break;
            default:
              break;
          }
        }
      });

      this.filterParams = filterParams;
      this.updateUrl();
      this.searchTerm = filterParams?.search;
      this.authorUsername = filterParams?.authorUsername;
      this.assigneeUsernames = filterParams?.assigneeUsername;
    },
    updateUrl() {
      const queryParams = urlParamsToObject(window.location.search);
      const { authorUsername, assigneeUsername, search } = this.filterParams || {};

      if (authorUsername) {
        queryParams.author_username = authorUsername;
      } else {
        delete queryParams.author_username;
      }

      if (assigneeUsername) {
        queryParams.assignee_username = assigneeUsername;
      } else {
        delete queryParams.assignee_username;
      }

      if (search) {
        queryParams.search = search;
      } else {
        delete queryParams.search;
      }

      updateHistory({
        url: setUrlParams(queryParams, window.location.href, true),
        title: document.title,
        replace: true,
      });
    },
  },
};
</script>
<template>
  <div class="incident-management-list">
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="isErrorAlertDismissed = true">
      {{ $options.i18n.errorMsg }}
    </gl-alert>

    <div
      class="incident-management-list-header gl-display-flex gl-justify-content-space-between gl-border-b-solid gl-border-b-1 gl-border-gray-100"
    >
      <gl-tabs content-class="gl-p-0" @input="filterIncidentsByStatus">
        <gl-tab v-for="tab in $options.statusTabs" :key="tab.status" :data-testid="tab.status">
          <template #title>
            <span>{{ tab.title }}</span>
            <gl-badge v-if="incidentsCount" pill size="sm" class="gl-tab-counter-badge">
              {{ incidentsCount[tab.status.toLowerCase()] }}
            </gl-badge>
          </template>
        </gl-tab>
      </gl-tabs>

      <gl-button
        v-if="!isEmpty || activeClosedTabHasNoIncidents"
        class="gl-my-3 gl-mr-5 create-incident-button"
        data-testid="createIncidentBtn"
        data-qa-selector="create_incident_button"
        :loading="redirecting"
        :disabled="redirecting"
        category="primary"
        variant="success"
        :href="newIncidentPath"
        @click="redirecting = true"
      >
        {{ $options.i18n.createIncidentBtnLabel }}
      </gl-button>
    </div>

    <div class="filtered-search-wrapper">
      <filtered-search-bar
        :namespace="projectPath"
        :search-input-placeholder="$options.i18n.searchPlaceholder"
        :tokens="filteredSearchTokens"
        :initial-filter-value="filteredSearchValue"
        initial-sortby="created_desc"
        recent-searches-storage-key="incidents"
        class="row-content-block"
        @onFilter="handleFilterIncidents"
      />
    </div>

    <h4 class="gl-display-block d-md-none my-3">
      {{ s__('IncidentManagement|Incidents') }}
    </h4>
    <gl-table
      v-if="showList"
      :items="incidents.list || []"
      :fields="availableFields"
      :show-empty="true"
      :busy="loading"
      stacked="md"
      :tbody-tr-class="tbodyTrClass"
      :no-local-sorting="true"
      :sort-direction="'desc'"
      :sort-desc.sync="sortDesc"
      :sort-by.sync="sortBy"
      sort-icon-left
      fixed
      @row-clicked="navigateToIncidentDetails"
      @sort-changed="fetchSortedData"
    >
      <template #cell(severity)="{ item }">
        <severity-token :severity="getSeverity(item.severity)" />
      </template>

      <template #cell(title)="{ item }">
        <div :class="{ 'gl-display-flex gl-align-items-center': item.state === 'closed' }">
          <div class="gl-max-w-full text-truncate" :title="item.title">{{ item.title }}</div>
          <gl-icon
            v-if="item.state === 'closed'"
            name="issue-close"
            class="gl-mx-1 gl-fill-blue-500 gl-flex-shrink-0"
            :size="16"
            data-testid="incident-closed"
          />
        </div>
      </template>

      <template #cell(createdAt)="{ item }">
        <time-ago-tooltip :time="item.createdAt" />
      </template>

      <template #cell(assignees)="{ item }">
        <div data-testid="incident-assignees">
          <template v-if="hasAssignees(item.assignees)">
            <gl-avatars-inline
              :avatars="item.assignees.nodes"
              :collapsed="true"
              :max-visible="4"
              :avatar-size="24"
              badge-tooltip-prop="name"
              :badge-tooltip-max-chars="100"
            >
              <template #avatar="{ avatar }">
                <gl-avatar-link
                  :key="avatar.username"
                  v-gl-tooltip
                  target="_blank"
                  :href="avatar.webUrl"
                  :title="avatar.name"
                >
                  <gl-avatar :src="avatar.avatarUrl" :label="avatar.name" :size="24" />
                </gl-avatar-link>
              </template>
            </gl-avatars-inline>
          </template>
          <template v-else>
            {{ $options.i18n.unassigned }}
          </template>
        </div>
      </template>

      <template v-if="publishedAvailable" #cell(published)="{ item }">
        <published-cell
          :status-page-published-incident="item.statusPagePublishedIncident"
          :un-published="$options.i18n.unPublished"
        />
      </template>
      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="mt-3" />
      </template>

      <template v-if="errored" #empty>
        {{ $options.i18n.noIncidents }}
      </template>
    </gl-table>

    <gl-empty-state
      v-else
      :title="emptyStateData.title"
      :svg-path="emptyListSvgPath"
      :description="emptyStateData.description"
      :primary-button-link="emptyStateData.btnLink"
      :primary-button-text="emptyStateData.btnText"
    />

    <gl-pagination
      v-if="showPaginationControls"
      :value="pagination.currentPage"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-pagination gl-mt-3"
      @input="handlePageChange"
    />
  </div>
</template>
