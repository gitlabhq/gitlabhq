<script>
/* eslint-disable vue/no-v-html */
import {
  GlLoadingIcon,
  GlTable,
  GlAlert,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlIcon,
  GlLink,
  GlTabs,
  GlTab,
  GlBadge,
  GlPagination,
  GlSearchBoxByType,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { debounce, trim } from 'lodash';
import { __, s__ } from '~/locale';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { fetchPolicies } from '~/lib/graphql';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import Tracking from '~/tracking';
import getAlerts from '../graphql/queries/get_alerts.query.graphql';
import getAlertsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';
import {
  ALERTS_STATUS_TABS,
  ALERTS_SEVERITY_LABELS,
  DEFAULT_PAGE_SIZE,
  trackAlertListViewsOptions,
  trackAlertStatusUpdateOptions,
} from '../constants';
import AlertStatus from './alert_status.vue';

const tdClass =
  'table-col gl-display-flex d-md-table-cell gl-align-items-center gl-white-space-nowrap';
const thClass = 'gl-hover-bg-blue-50';
const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 gl-hover-bg-blue-50 gl-hover-cursor-pointer gl-hover-border-b-solid gl-hover-border-blue-200';
const TH_TEST_ID = { 'data-testid': 'alert-management-severity-sort' };

const initialPaginationState = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: DEFAULT_PAGE_SIZE,
  lastPageSize: null,
};

const TWELVE_HOURS_IN_MS = 12 * 60 * 60 * 1000;

export default {
  i18n: {
    noAlertsMsg: s__(
      'AlertManagement|No alerts available to display. See %{linkStart}enabling alert management%{linkEnd} for more information on adding alerts to the list.',
    ),
    errorMsg: s__(
      "AlertManagement|There was an error displaying the alerts. Confirm your endpoint's configuration details to ensure alerts appear.",
    ),
    searchPlaceholder: __('Search or filter results...'),
    unassigned: __('Unassigned'),
  },
  fields: [
    {
      key: 'severity',
      label: s__('AlertManagement|Severity'),
      thClass: `${thClass} gl-w-eighth`,
      thAttr: TH_TEST_ID,
      tdClass: `${tdClass} rounded-top text-capitalize sortable-cell`,
      sortable: true,
    },
    {
      key: 'startedAt',
      label: s__('AlertManagement|Start time'),
      thClass: `${thClass} js-started-at w-15p`,
      tdClass: `${tdClass} sortable-cell`,
      sortable: true,
    },
    {
      key: 'alertLabel',
      label: s__('AlertManagement|Alert'),
      thClass: `gl-pointer-events-none`,
      tdClass,
    },
    {
      key: 'eventCount',
      label: s__('AlertManagement|Events'),
      thClass: `${thClass} text-right gl-w-12`,
      tdClass: `${tdClass} text-md-right sortable-cell`,
      sortable: true,
    },
    {
      key: 'issue',
      label: s__('AlertManagement|Issue'),
      thClass: 'gl-w-12 gl-pointer-events-none',
      tdClass,
    },
    {
      key: 'assignees',
      label: s__('AlertManagement|Assignees'),
      thClass: 'gl-w-eighth gl-pointer-events-none',
      tdClass,
    },
    {
      key: 'status',
      label: s__('AlertManagement|Status'),
      thClass: `${thClass} w-15p`,
      tdClass: `${tdClass} rounded-bottom sortable-cell`,
      sortable: true,
    },
  ],
  severityLabels: ALERTS_SEVERITY_LABELS,
  statusTabs: ALERTS_STATUS_TABS,
  components: {
    GlLoadingIcon,
    GlTable,
    GlAlert,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
    TimeAgo,
    GlIcon,
    GlLink,
    GlTabs,
    GlTab,
    GlBadge,
    GlPagination,
    GlSearchBoxByType,
    GlSprintf,
    AlertStatus,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    populatingAlertsHelpUrl: {
      type: String,
      required: true,
    },
  },
  apollo: {
    alerts: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getAlerts,
      variables() {
        return {
          searchTerm: this.searchTerm,
          projectPath: this.projectPath,
          statuses: this.statusFilter,
          sort: this.sort,
          firstPageSize: this.pagination.firstPageSize,
          lastPageSize: this.pagination.lastPageSize,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
        };
      },
      update(data) {
        const { alertManagementAlerts: { nodes: list = [], pageInfo = {} } = {} } =
          data.project || {};
        const now = new Date();

        const listWithData = list.map(alert => {
          const then = new Date(alert.startedAt);
          const diff = now - then;

          return {
            ...alert,
            isNew: diff < TWELVE_HOURS_IN_MS,
          };
        });

        return {
          list: listWithData,
          pageInfo,
        };
      },
      error() {
        this.hasError = true;
      },
    },
    alertsCount: {
      query: getAlertsCountByStatus,
      variables() {
        return {
          searchTerm: this.searchTerm,
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data.project?.alertManagementAlertStatusCounts;
      },
    },
  },
  data() {
    return {
      searchTerm: '',
      hasError: false,
      errorMessage: '',
      isAlertDismissed: false,
      sort: 'STARTED_AT_DESC',
      statusFilter: [],
      filteredByStatus: '',
      pagination: initialPaginationState,
      sortBy: 'startedAt',
      sortDesc: true,
      sortDirection: 'desc',
    };
  },
  computed: {
    showNoAlertsMsg() {
      return (
        !this.hasError &&
        !this.loading &&
        this.alertsCount?.all === 0 &&
        !this.searchTerm &&
        !this.isAlertDismissed
      );
    },
    loading() {
      return this.$apollo.queries.alerts.loading;
    },
    hasAlerts() {
      return this.alerts?.list?.length;
    },
    showPaginationControls() {
      return Boolean(this.prevPage || this.nextPage);
    },
    alertsForCurrentTab() {
      return this.alertsCount ? this.alertsCount[this.filteredByStatus.toLowerCase()] : 0;
    },
    prevPage() {
      return Math.max(this.pagination.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.pagination.currentPage + 1;
      return nextPage > Math.ceil(this.alertsForCurrentTab / DEFAULT_PAGE_SIZE) ? null : nextPage;
    },
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    filterAlertsByStatus(tabIndex) {
      this.resetPagination();
      const { filters, status } = this.$options.statusTabs[tabIndex];
      this.statusFilter = filters;
      this.filteredByStatus = status;
    },
    fetchSortedData({ sortBy, sortDesc }) {
      const sortingDirection = sortDesc ? 'DESC' : 'ASC';
      const sortingColumn = convertToSnakeCase(sortBy).toUpperCase();

      this.resetPagination();
      this.sort = `${sortingColumn}_${sortingDirection}`;
    },
    onInputChange: debounce(function debounceSearch(input) {
      const trimmedInput = trim(input);
      if (trimmedInput !== this.searchTerm) {
        this.resetPagination();
        this.searchTerm = trimmedInput;
      }
    }, 500),
    navigateToAlertDetails({ iid }, index, { metaKey }) {
      return visitUrl(joinPaths(window.location.pathname, iid, 'details'), metaKey);
    },
    trackPageViews() {
      const { category, action } = trackAlertListViewsOptions;
      Tracking.event(category, action);
    },
    trackStatusUpdate(status) {
      const { category, action, label } = trackAlertStatusUpdateOptions;
      Tracking.event(category, action, { label, property: status });
    },
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    getIssueLink(item) {
      return joinPaths('/', this.projectPath, '-', 'issues', item.issueIid);
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.alerts.pageInfo;

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
    tbodyTrClass(item) {
      return {
        [bodyTrClass]: !this.loading && this.hasAlerts,
        'new-alert': item?.isNew,
      };
    },
    handleAlertError(errorMessage) {
      this.hasError = true;
      this.errorMessage = errorMessage;
    },
    dismissError() {
      this.hasError = false;
      this.errorMessage = '';
    },
  },
};
</script>
<template>
  <div>
    <div class="incident-management-list">
      <gl-alert v-if="showNoAlertsMsg" @dismiss="isAlertDismissed = true">
        <gl-sprintf :message="$options.i18n.noAlertsMsg">
          <template #link="{ content }">
            <gl-link
              class="gl-display-inline-block"
              :href="populatingAlertsHelpUrl"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
      <gl-alert v-if="hasError" variant="danger" data-testid="alert-error" @dismiss="dismissError">
        <p v-html="errorMessage || $options.i18n.errorMsg"></p>
      </gl-alert>

      <gl-tabs
        content-class="gl-p-0 gl-border-b-solid gl-border-b-1 gl-border-gray-100"
        @input="filterAlertsByStatus"
      >
        <gl-tab v-for="tab in $options.statusTabs" :key="tab.status">
          <template slot="title">
            <span>{{ tab.title }}</span>
            <gl-badge v-if="alertsCount" pill size="sm" class="gl-tab-counter-badge">
              {{ alertsCount[tab.status.toLowerCase()] }}
            </gl-badge>
          </template>
        </gl-tab>
      </gl-tabs>

      <div class="gl-bg-gray-10 gl-p-5 gl-border-b-solid gl-border-b-1 gl-border-gray-100">
        <gl-search-box-by-type
          class="gl-bg-white"
          :placeholder="$options.i18n.searchPlaceholder"
          @input="onInputChange"
        />
      </div>

      <h4 class="d-block d-md-none my-3">
        {{ s__('AlertManagement|Alerts') }}
      </h4>
      <gl-table
        class="alert-management-table"
        :items="alerts ? alerts.list : []"
        :fields="$options.fields"
        :show-empty="true"
        :busy="loading"
        stacked="md"
        :tbody-tr-class="tbodyTrClass"
        :no-local-sorting="true"
        :sort-direction="sortDirection"
        :sort-desc.sync="sortDesc"
        :sort-by.sync="sortBy"
        sort-icon-left
        fixed
        @row-clicked="navigateToAlertDetails"
        @sort-changed="fetchSortedData"
      >
        <template #cell(severity)="{ item }">
          <div
            class="d-inline-flex align-items-center justify-content-between"
            data-testid="severityField"
          >
            <gl-icon
              class="mr-2"
              :size="12"
              :name="`severity-${item.severity.toLowerCase()}`"
              :class="`icon-${item.severity.toLowerCase()}`"
            />
            {{ $options.severityLabels[item.severity] }}
          </div>
        </template>

        <template #cell(startedAt)="{ item }">
          <time-ago v-if="item.startedAt" :time="item.startedAt" />
        </template>

        <template #cell(eventCount)="{ item }">
          {{ item.eventCount }}
        </template>

        <template #cell(alertLabel)="{ item }">
          <div
            class="gl-max-w-full text-truncate"
            :title="`${item.iid} - ${item.title}`"
            data-testid="idField"
          >
            #{{ item.iid }} {{ item.title }}
          </div>
        </template>

        <template #cell(issue)="{ item }">
          <gl-link v-if="item.issueIid" data-testid="issueField" :href="getIssueLink(item)">
            #{{ item.issueIid }}
          </gl-link>
          <div v-else data-testid="issueField">{{ s__('AlertManagement|None') }}</div>
        </template>

        <template #cell(assignees)="{ item }">
          <div data-testid="assigneesField">
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

        <template #cell(status)="{ item }">
          <alert-status
            :alert="item"
            :project-path="projectPath"
            :is-sidebar="false"
            @alert-error="handleAlertError"
          />
        </template>

        <template #empty>
          {{ s__('AlertManagement|No alerts to display.') }}
        </template>

        <template #table-busy>
          <gl-loading-icon size="lg" color="dark" class="mt-3" />
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
  </div>
</template>
