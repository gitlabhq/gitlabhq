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
} from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { fetchPolicies } from '~/lib/graphql';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import getAlerts from '../graphql/queries/get_alerts.query.graphql';
import getAlertsCountByStatus from '../graphql/queries/get_count_by_status.query.graphql';
import { ALERTS_STATUS, ALERTS_STATUS_TABS, ALERTS_SEVERITY_LABELS } from '../constants';
import updateAlertStatus from '../graphql/mutations/update_alert_status.graphql';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

const tdClass = 'table-col d-flex d-md-table-cell align-items-center';
const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 hover-bg-blue-50 hover-gl-cursor-pointer hover-gl-border-b-solid hover-gl-border-blue-200';

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
    },
    {
      key: 'startedAt',
      label: s__('AlertManagement|Start time'),
      tdClass,
    },
    {
      key: 'endedAt',
      label: s__('AlertManagement|End time'),
      tdClass,
    },
    {
      key: 'title',
      label: s__('AlertManagement|Alert'),
      thClass: 'w-30p',
      tdClass,
    },
    {
      key: 'eventCount',
      label: s__('AlertManagement|Events'),
      thClass: 'text-right gl-pr-9',
      tdClass: `${tdClass} text-md-right`,
    },
    {
      key: 'status',
      thClass: 'w-15p',
      label: s__('AlertManagement|Status'),
      tdClass: `${tdClass} rounded-bottom`,
    },
  ],
  statuses: {
    [ALERTS_STATUS.TRIGGERED]: s__('AlertManagement|Triggered'),
    [ALERTS_STATUS.ACKNOWLEDGED]: s__('AlertManagement|Acknowledged'),
    [ALERTS_STATUS.RESOLVED]: s__('AlertManagement|Resolved'),
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
        };
      },
      update(data) {
        return data.project?.alertManagementAlerts?.nodes;
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
      statusFilter: this.$options.statusTabs[4].filters,
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
      return this.alerts?.length;
    },
    tbodyTrClass() {
      return !this.loading && this.hasAlerts ? bodyTrClass : '';
    },
  },
  methods: {
    filterAlertsByStatus(tabIndex) {
      this.statusFilter = this.$options.statusTabs[tabIndex].filters;
    },
    capitalizeFirstCharacter,
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
          this.$apollo.queries.alerts.refetch();
          this.$apollo.queries.alertsCount.refetch();
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
        :items="alerts"
        :fields="$options.fields"
        :show-empty="true"
        :busy="loading"
        stacked="md"
        :tbody-tr-class="tbodyTrClass"
        @row-clicked="navigateToAlertDetails"
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

        <template #cell(title)="{ item }">
          <div class="gl-max-w-full text-truncate">{{ item.title }}</div>
        </template>

        <template #cell(status)="{ item }">
          <gl-dropdown
            :text="capitalizeFirstCharacter(item.status.toLowerCase())"
            class="w-100"
            right
          >
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
