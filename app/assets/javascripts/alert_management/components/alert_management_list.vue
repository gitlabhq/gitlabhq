<script>
import {
  GlEmptyState,
  GlDeprecatedButton,
  GlLoadingIcon,
  GlTable,
  GlAlert,
  GlIcon,
  GlDropdown,
  GlDropdownItem,
  GlTabs,
  GlTab,
  GlBadge,
  GlPagination,
} from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { fetchPolicies } from '~/lib/graphql';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import getAlerts from '../graphql/queries/get_alerts.query.graphql';
import getAlertsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';
import {
  ALERTS_STATUS_TABS,
  ALERTS_SEVERITY_LABELS,
  DEFAULT_PAGE_SIZE,
  trackAlertListViewsOptions,
  trackAlertStatusUpdateOptions,
} from '../constants';
import updateAlertStatus from '../graphql/mutations/update_alert_status.graphql';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import Tracking from '~/tracking';

const tdClass = 'table-col gl-display-flex d-md-table-cell gl-align-items-center';
const thClass = 'gl-hover-bg-blue-50';
const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 gl-hover-bg-blue-50 gl-hover-cursor-pointer gl-hover-border-b-solid gl-hover-border-blue-200';

const initialPaginationState = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: DEFAULT_PAGE_SIZE,
  lastPageSize: null,
};

export default {
  i18n: {
    noAlertsMsg: s__(
      "AlertManagement|No alerts available to display. If you think you're seeing this message in error, refresh the page.",
    ),
    errorMsg: s__(
      "AlertManagement|There was an error displaying the alerts. Confirm your endpoint's configuration details to ensure alerts appear.",
    ),
  },
  fields: [
    {
      key: 'severity',
      label: s__('AlertManagement|Severity'),
      tdClass: `${tdClass} rounded-top text-capitalize`,
      thClass,
      sortable: true,
    },
    {
      key: 'startedAt',
      label: s__('AlertManagement|Start time'),
      thClass: `${thClass} js-started-at`,
      tdClass,
      sortable: true,
    },
    {
      key: 'endedAt',
      label: s__('AlertManagement|End time'),
      thClass,
      tdClass,
      sortable: true,
    },
    {
      key: 'title',
      label: s__('AlertManagement|Alert'),
      thClass: `${thClass} w-30p gl-pointer-events-none`,
      tdClass,
      sortable: false,
    },
    {
      key: 'eventCount',
      label: s__('AlertManagement|Events'),
      thClass: `${thClass} text-right gl-pr-9 w-3rem`,
      tdClass: `${tdClass} text-md-right`,
      sortable: true,
    },
    {
      key: 'assignees',
      label: s__('AlertManagement|Assignees'),
      tdClass,
    },
    {
      key: 'status',
      thClass: `${thClass} w-15p`,
      label: s__('AlertManagement|Status'),
      tdClass: `${tdClass} rounded-bottom`,
      sortable: true,
    },
  ],
  statuses: {
    TRIGGERED: s__('AlertManagement|Triggered'),
    ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
    RESOLVED: s__('AlertManagement|Resolved'),
  },
  severityLabels: ALERTS_SEVERITY_LABELS,
  statusTabs: ALERTS_STATUS_TABS,
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlTable,
    GlAlert,
    GlDeprecatedButton,
    TimeAgo,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlTabs,
    GlTab,
    GlBadge,
    GlPagination,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    alertManagementEnabled: {
      type: Boolean,
      required: true,
    },
    enableAlertManagementPath: {
      type: String,
      required: true,
    },
    userCanEnableAlertManagement: {
      type: Boolean,
      required: true,
    },
    emptyAlertSvgPath: {
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

        return {
          list,
          pageInfo,
        };
      },
      error() {
        this.errored = true;
      },
    },
    alertsCount: {
      query: getAlertsCountByStatus,
      variables() {
        return {
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
      errored: false,
      isAlertDismissed: false,
      isErrorAlertDismissed: false,
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
        !this.errored && !this.loading && this.alertsCount?.all === 0 && !this.isAlertDismissed
      );
    },
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed;
    },
    loading() {
      return this.$apollo.queries.alerts.loading;
    },
    hasAlerts() {
      return this.alerts?.list?.length;
    },
    tbodyTrClass() {
      return !this.loading && this.hasAlerts ? bodyTrClass : '';
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
    updateAlertStatus(status, iid) {
      this.$apollo
        .mutate({
          mutation: updateAlertStatus,
          variables: {
            iid,
            status: status.toUpperCase(),
            projectPath: this.projectPath,
          },
        })
        .then(() => {
          this.trackStatusUpdate(status);
          this.$apollo.queries.alerts.refetch();
          this.$apollo.queries.alertsCount.refetch();
          this.resetPagination();
        })
        .catch(() => {
          createFlash(
            s__(
              'AlertManagement|There was an error while updating the status of the alert. Please try again.',
            ),
          );
        });
    },
    navigateToAlertDetails({ iid }) {
      return visitUrl(joinPaths(window.location.pathname, iid, 'details'));
    },
    trackPageViews() {
      const { category, action } = trackAlertListViewsOptions;
      Tracking.event(category, action);
    },
    trackStatusUpdate(status) {
      const { category, action, label } = trackAlertStatusUpdateOptions;
      Tracking.event(category, action, { label, property: status });
    },
    getAssignees(assignees) {
      // TODO: Update to show list of assignee(s) after https://gitlab.com/gitlab-org/gitlab/-/issues/218405
      return assignees.nodes?.length > 0
        ? assignees.nodes[0]?.username
        : s__('AlertManagement|Unassigned');
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
  },
};
</script>
<template>
  <div>
    <div v-if="alertManagementEnabled" class="alert-management-list">
      <gl-alert v-if="showNoAlertsMsg" @dismiss="isAlertDismissed = true">
        {{ $options.i18n.noAlertsMsg }}
      </gl-alert>
      <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="isErrorAlertDismissed = true">
        {{ $options.i18n.errorMsg }}
      </gl-alert>

      <gl-tabs @input="filterAlertsByStatus">
        <gl-tab v-for="tab in $options.statusTabs" :key="tab.status">
          <template slot="title">
            <span>{{ tab.title }}</span>
            <gl-badge v-if="alertsCount" pill size="sm" class="gl-tab-counter-badge">
              {{ alertsCount[tab.status.toLowerCase()] }}
            </gl-badge>
          </template>
        </gl-tab>
      </gl-tabs>

      <h4 class="d-block d-md-none my-3">
        {{ s__('AlertManagement|Alerts') }}
      </h4>
      <gl-table
        class="alert-management-table mt-3"
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

        <template #cell(endedAt)="{ item }">
          <time-ago v-if="item.endedAt" :time="item.endedAt" />
        </template>

        <template #cell(eventCount)="{ item }">
          {{ item.eventCount }}
        </template>

        <template #cell(title)="{ item }">
          <div class="gl-max-w-full text-truncate">{{ item.title }}</div>
        </template>

        <template #cell(assignees)="{ item }">
          <div class="gl-max-w-full text-truncate" data-testid="assigneesField">
            {{ getAssignees(item.assignees) }}
          </div>
        </template>

        <template #cell(status)="{ item }">
          <gl-dropdown :text="$options.statuses[item.status]" class="w-100" right>
            <gl-dropdown-item
              v-for="(label, field) in $options.statuses"
              :key="field"
              @click="updateAlertStatus(label, item.iid)"
            >
              <span class="d-flex">
                <gl-icon
                  class="flex-shrink-0 append-right-4"
                  :class="{ invisible: label.toUpperCase() !== item.status }"
                  name="mobile-issue-close"
                />
                {{ label }}
              </span>
            </gl-dropdown-item>
          </gl-dropdown>
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
        class="gl-pagination prepend-top-default"
        @input="handlePageChange"
      />
    </div>
    <gl-empty-state
      v-else
      :title="s__('AlertManagement|Surface alerts in GitLab')"
      :svg-path="emptyAlertSvgPath"
    >
      <template #description>
        <div class="d-block">
          <span>{{
            s__(
              'AlertManagement|Display alerts from all your monitoring tools directly within GitLab. Streamline the investigation of your alerts and the escalation of alerts to incidents.',
            )
          }}</span>
          <a href="/help/user/project/operations/alert_management.html" target="_blank">
            {{ s__('AlertManagement|More information') }}
          </a>
        </div>
        <div v-if="userCanEnableAlertManagement" class="d-block center pt-4">
          <gl-deprecated-button
            category="primary"
            variant="success"
            :href="enableAlertManagementPath"
          >
            {{ s__('AlertManagement|Authorize external service') }}
          </gl-deprecated-button>
        </div>
      </template>
    </gl-empty-state>
  </div>
</template>
