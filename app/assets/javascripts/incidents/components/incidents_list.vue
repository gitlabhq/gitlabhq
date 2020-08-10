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
  GlSearchBoxByType,
  GlIcon,
  GlPagination,
  GlTabs,
  GlTab,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import { mergeUrlParams, joinPaths, visitUrl } from '~/lib/utils/url_utility';
import getIncidents from '../graphql/queries/get_incidents.query.graphql';
import { I18N, DEFAULT_PAGE_SIZE, INCIDENT_SEARCH_DELAY, INCIDENT_STATE_TABS } from '../constants';

const TH_TEST_ID = { 'data-testid': 'incident-management-created-at-sort' };
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
  stateTabs: INCIDENT_STATE_TABS,
  fields: [
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
      thAttr: TH_TEST_ID,
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
    GlSearchBoxByType,
    GlIcon,
    GlPagination,
    GlTabs,
    GlTab,
    PublishedCell: () => import('ee_component/incidents/components/published_cell.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'projectPath',
    'newIssuePath',
    'incidentTemplateName',
    'issuePath',
    'publishedAvailable',
  ],
  apollo: {
    incidents: {
      query: getIncidents,
      variables() {
        return {
          searchTerm: this.searchTerm,
          state: this.stateFilter,
          projectPath: this.projectPath,
          issueTypes: ['INCIDENT'],
          sort: this.sort,
          firstPageSize: this.pagination.firstPageSize,
          lastPageSize: this.pagination.lastPageSize,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
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
  },
  data() {
    return {
      errored: false,
      isErrorAlertDismissed: false,
      redirecting: false,
      searchTerm: '',
      pagination: initialPaginationState,
      incidents: {},
      stateFilter: '',
      sort: 'created_desc',
      sortBy: 'createdAt',
      sortDesc: true,
    };
  },
  computed: {
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed && !this.searchTerm;
    },
    loading() {
      return this.$apollo.queries.incidents.loading;
    },
    hasIncidents() {
      return this.incidents?.list?.length;
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
      return this.incidents?.list?.length < DEFAULT_PAGE_SIZE ? null : nextPage;
    },
    tbodyTrClass() {
      return {
        [bodyTrClass]: !this.loading && this.hasIncidents,
      };
    },
    newIncidentPath() {
      return mergeUrlParams({ issuable_template: this.incidentTemplateName }, this.newIssuePath);
    },
    availableFields() {
      return this.publishedAvailable
        ? [
            ...this.$options.fields,
            ...[
              {
                key: 'published',
                label: s__('IncidentManagement|Published'),
                thClass: 'gl-pointer-events-none',
              },
            ],
          ]
        : this.$options.fields;
    },
  },
  methods: {
    onInputChange: debounce(function debounceSearch(input) {
      const trimmedInput = input.trim();
      if (trimmedInput !== this.searchTerm) {
        this.searchTerm = trimmedInput;
      }
    }, INCIDENT_SEARCH_DELAY),
    filterIncidentsByState(tabIndex) {
      const { filters } = this.$options.stateTabs[tabIndex];
      this.stateFilter = filters;
    },
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    navigateToIncidentDetails({ iid }) {
      return visitUrl(joinPaths(this.issuePath, iid));
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
      const sortingDirection = sortDesc ? 'desc' : 'asc';
      const sortingColumn = convertToSnakeCase(sortBy).replace(/_.*/, '');

      this.sort = `${sortingColumn}_${sortingDirection}`;
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
      <gl-tabs content-class="gl-p-0" @input="filterIncidentsByState">
        <gl-tab v-for="tab in $options.stateTabs" :key="tab.state" :data-testid="tab.state">
          <template #title>
            <span>{{ tab.title }}</span>
          </template>
        </gl-tab>
      </gl-tabs>

      <gl-button
        class="gl-my-3 gl-mr-5 create-incident-button"
        data-testid="createIncidentBtn"
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

    <div class="gl-bg-gray-10 gl-p-5 gl-border-b-solid gl-border-b-1 gl-border-gray-100">
      <gl-search-box-by-type
        :value="searchTerm"
        class="gl-bg-white"
        :placeholder="$options.i18n.searchPlaceholder"
        @input="onInputChange"
      />
    </div>

    <h4 class="gl-display-block d-md-none my-3">
      {{ s__('IncidentManagement|Incidents') }}
    </h4>
    <gl-table
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

      <template #empty>
        {{ $options.i18n.noIncidents }}
      </template>
    </gl-table>

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
