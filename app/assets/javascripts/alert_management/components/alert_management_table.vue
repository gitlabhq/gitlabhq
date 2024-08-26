<script>
import {
  GlAlert,
  GlLoadingIcon,
  GlTable,
  GlAvatarsInline,
  GlAvatarLink,
  GlAvatar,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import getAlertsQuery from '~/graphql_shared/queries/get_alerts.query.graphql';
import { STATUS_CLOSED } from '~/issues/constants';
import { sortObjectToString } from '~/lib/utils/table_utility';
import { fetchPolicies } from '~/lib/graphql';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { s__, __, n__ } from '~/locale';
import AlertStatus from '~/vue_shared/alert_details/components/alert_status.vue';
import { TOKEN_TYPE_ASSIGNEE } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  tdClass,
  bodyTrClass,
  initialPaginationState,
} from '~/vue_shared/components/paginated_table_with_search_and_tabs/constants';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { ALERTS_STATUS_TABS, SEVERITY_LEVELS, trackAlertListViewsOptions } from '../constants';
import getAlertsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';

const TH_TEST_ID = { 'data-testid': 'alert-management-severity-sort' };

const TWELVE_HOURS_IN_MS = 12 * 60 * 60 * 1000;

const MAX_VISIBLE_ASSIGNEES = 4;

export default {
  trackAlertListViewsOptions,
  MAX_VISIBLE_ASSIGNEES,
  i18n: {
    noAlertsMsg: s__(
      'AlertManagement|No alerts available to display. See %{linkStart}enabling alert management%{linkEnd} for more information on adding alerts to the list.',
    ),
    errorMsg: s__(
      "AlertManagement|There was an error displaying the alerts. Confirm your endpoint's configuration details to ensure alerts appear.",
    ),
    unassigned: __('Unassigned'),
    closed: __('closed'),
  },
  fields: [
    {
      key: 'severity',
      label: s__('AlertManagement|Severity'),
      variant: 'secondary',
      thClass: `gl-w-1/8`,
      thAttr: TH_TEST_ID,
      tdClass: `${tdClass} rounded-top text-capitalize sortable-cell`,
      sortable: true,
    },
    {
      key: 'startedAt',
      label: s__('AlertManagement|Start time'),
      variant: 'secondary',
      thClass: `js-started-at gl-w-3/20`,
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
      variant: 'secondary',
      tdClass: `${tdClass} sortable-cell`,
      sortable: true,
    },
    {
      key: 'issue',
      label: s__('AlertManagement|Incident'),
      thClass: 'gl-w-3/20 gl-pointer-events-none',
      tdClass,
    },
    {
      key: 'assignees',
      label: s__('AlertManagement|Assignees'),
      thClass: 'gl-w-1/8 gl-pointer-events-none',
      tdClass,
    },
    {
      key: 'status',
      label: s__('AlertManagement|Status'),
      variant: 'secondary',
      thClass: `gl-w-3/20`,
      tdClass: `${tdClass} rounded-bottom sortable-cell`,
      sortable: true,
    },
  ],
  filterSearchTokens: [TOKEN_TYPE_ASSIGNEE],
  severityLabels: SEVERITY_LEVELS,
  statusTabs: ALERTS_STATUS_TABS,
  components: {
    GlAlert,
    GlLoadingIcon,
    GlTable,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
    TimeAgo,
    GlIcon,
    GlLink,
    GlSprintf,
    AlertStatus,
    PaginatedTableWithSearchAndTabs,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath', 'textQuery', 'assigneeUsernameQuery', 'populatingAlertsHelpUrl'],
  apollo: {
    alerts: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getAlertsQuery,
      variables() {
        return {
          searchTerm: this.searchTerm,
          assigneeUsername: this.assigneeUsername,
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

        const listWithData = list.map((alert) => {
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
        this.errored = true;
      },
    },
    alertsCount: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getAlertsCountByStatus,
      variables() {
        return {
          searchTerm: this.searchTerm,
          assigneeUsername: this.assigneeUsername,
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
      serverErrorMessage: '',
      isErrorAlertDismissed: false,
      sort: 'STARTED_AT_DESC',
      statusFilter: ALERTS_STATUS_TABS[0].filters,
      filteredByStatus: ALERTS_STATUS_TABS[0].status,
      alerts: {},
      alertsCount: {},
      sortBy: 'startedAt',
      sortDesc: true,
      sortDirection: 'desc',
      searchTerm: this.textQuery,
      assigneeUsername: this.assigneeUsernameQuery,
      pagination: initialPaginationState,
    };
  },
  computed: {
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed;
    },
    showNoAlertsMsg() {
      return (
        !this.errored &&
        !this.loading &&
        this.alertsCount?.all === 0 &&
        !this.searchTerm &&
        !this.assigneeUsername &&
        !this.isErrorAlertDismissed
      );
    },
    loading() {
      return this.$apollo.queries.alerts.loading;
    },
    isEmpty() {
      return !this.alerts?.list?.length;
    },
  },
  methods: {
    fetchSortedData({ sortBy, sortDesc }) {
      this.pagination = initialPaginationState;
      this.sort = sortObjectToString({ sortBy, sortDesc });
    },
    showAlertLink({ iid }) {
      return joinPaths(window.location.pathname, iid, 'details');
    },
    navigateToAlertDetails({ iid }, index, { metaKey }) {
      return visitUrl(this.showAlertLink({ iid }), metaKey);
    },
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    getIssueMeta({ issue: { iid, state } }) {
      return {
        state: state === STATUS_CLOSED ? `(${this.$options.i18n.closed})` : '',
        link: joinPaths('/', this.projectPath, '-', 'issues/incident', iid),
      };
    },
    tbodyTrClass(item) {
      return {
        [bodyTrClass]: !this.loading && !this.isEmpty,
        'new-alert': item?.isNew,
      };
    },
    handleAlertError(errorMessage) {
      this.errored = true;
      this.serverErrorMessage = errorMessage;
    },
    handleStatusUpdate() {
      this.$apollo.queries.alerts.refetch();
      this.$apollo.queries.alertsCount.refetch();
    },
    pageChanged(pagination) {
      this.pagination = pagination;
    },
    statusChanged({ filters, status }) {
      this.statusFilter = filters;
      this.filteredByStatus = status;
    },
    filtersChanged({ searchTerm, assigneeUsername }) {
      this.searchTerm = searchTerm;
      this.assigneeUsername = assigneeUsername;
    },
    errorAlertDismissed() {
      this.errored = false;
      this.serverErrorMessage = '';
      this.isErrorAlertDismissed = true;
    },
    assigneesBadgeSrOnlyText(item) {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        item.assignees.nodes.length - MAX_VISIBLE_ASSIGNEES,
      );
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showNoAlertsMsg" @dismiss="errorAlertDismissed">
      <gl-sprintf :message="$options.i18n.noAlertsMsg">
        <template #link="{ content }">
          <gl-link class="gl-inline-block" :href="populatingAlertsHelpUrl" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <paginated-table-with-search-and-tabs
      :show-error-msg="showErrorMsg"
      :i18n="$options.i18n"
      :items="
        alerts.list || [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
      "
      :page-info="alerts.pageInfo"
      :items-count="alertsCount"
      :status-tabs="$options.statusTabs"
      :track-views-options="$options.trackAlertListViewsOptions"
      :server-error-message="serverErrorMessage"
      :filter-search-tokens="$options.filterSearchTokens"
      filter-search-key="alerts"
      class="incident-management-list"
      @page-changed="pageChanged"
      @tabs-changed="statusChanged"
      @filters-changed="filtersChanged"
      @error-alert-dismissed="errorAlertDismissed"
    >
      <template #header-actions></template>

      <template #title>
        {{ s__('AlertManagement|Alerts') }}
      </template>

      <template #table>
        <gl-table
          class="alert-management-table"
          data-testid="alert-table-container"
          :items="
            alerts
              ? alerts.list
              : [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
          "
          :fields="$options.fields"
          :show-empty="true"
          :busy="loading"
          stacked="md"
          :tbody-tr-class="tbodyTrClass"
          :no-local-sorting="true"
          :sort-direction="sortDirection"
          :sort-desc.sync="sortDesc"
          :sort-by.sync="sortBy"
          fixed
          hover
          selectable
          selected-variant="primary"
          @row-clicked="navigateToAlertDetails"
          @sort-changed="fetchSortedData"
        >
          <template #cell(severity)="{ item }">
            <div
              class="justify-content-between gl-inline-flex gl-items-center"
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
              class="text-truncate gl-max-w-full"
              :title="`${item.iid} - ${item.title}`"
              data-testid="idField"
            >
              <gl-link :href="showAlertLink(item)"> #{{ item.iid }} {{ item.title }} </gl-link>
            </div>
          </template>

          <template #cell(issue)="{ item }">
            <gl-link
              v-if="item.issue"
              v-gl-tooltip
              :title="item.issue.title"
              data-testid="issueField"
              :href="getIssueMeta(item).link"
            >
              #{{ item.issue.iid }} {{ getIssueMeta(item).state }}
            </gl-link>
            <div v-else data-testid="issueField">{{ s__('AlertManagement|None') }}</div>
          </template>

          <template #cell(assignees)="{ item }">
            <div data-testid="assigneesField">
              <template v-if="hasAssignees(item.assignees)">
                <gl-avatars-inline
                  :avatars="item.assignees.nodes"
                  :collapsed="true"
                  :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
                  :avatar-size="24"
                  badge-tooltip-prop="name"
                  :badge-tooltip-max-chars="100"
                  :badge-sr-only-text="assigneesBadgeSrOnlyText(item)"
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
              @hide-dropdown="handleStatusUpdate"
            />
          </template>

          <template #empty>
            {{ s__('AlertManagement|No alerts to display.') }}
          </template>

          <template #table-busy>
            <gl-loading-icon size="lg" color="dark" class="mt-3" />
          </template>
        </gl-table>
      </template>
    </paginated-table-with-search-and-tabs>
  </div>
</template>
