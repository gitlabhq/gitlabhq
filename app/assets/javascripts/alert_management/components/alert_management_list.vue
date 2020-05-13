<script>
import {
  GlEmptyState,
  GlDeprecatedButton,
  GlLoadingIcon,
  GlTable,
  GlAlert,
  GlIcon,
  GlNewDropdown,
  GlNewDropdownItem,
  GlTabs,
  GlTab,
  GlBadge,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import getAlerts from '../graphql/queries/getAlerts.query.graphql';
import { ALERTS_STATUS, ALERTS_STATUS_TABS } from '../constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const tdClass = 'table-col d-flex d-md-table-cell align-items-center';

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
      thClass: 'text-right event-count',
      tdClass: `${tdClass} text-md-right event-count`,
    },
    {
      key: 'status',
      label: s__('AlertManagement|Status'),
      tdClass: `${tdClass} rounded-bottom text-capitalize`,
    },
  ],
  statuses: {
    [ALERTS_STATUS.TRIGGERED]: s__('AlertManagement|Triggered'),
    [ALERTS_STATUS.ACKNOWLEDGED]: s__('AlertManagement|Acknowledged'),
    [ALERTS_STATUS.RESOLVED]: s__('AlertManagement|Resolved'),
  },
  statusTabs: ALERTS_STATUS_TABS,
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlTable,
    GlAlert,
    GlDeprecatedButton,
    TimeAgo,
    GlNewDropdown,
    GlNewDropdownItem,
    GlIcon,
    GlTabs,
    GlTab,
    GlBadge,
  },
  mixins: [glFeatureFlagsMixin()],
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
      query: getAlerts,
      variables() {
        return {
          projectPath: this.projectPath,
          status: this.statusFilter,
        };
      },
      update(data) {
        return data.project.alertManagementAlerts.nodes;
      },
      error() {
        this.errored = true;
      },
    },
  },
  data() {
    return {
      alerts: null,
      errored: false,
      isAlertDismissed: false,
      isErrorAlertDismissed: false,
      statusFilter: this.$options.statusTabs[0].status,
    };
  },
  computed: {
    showNoAlertsMsg() {
      return !this.errored && !this.loading && !this.alerts?.length && !this.isAlertDismissed;
    },
    showErrorMsg() {
      return this.errored && !this.isErrorAlertDismissed;
    },
    loading() {
      return this.$apollo.queries.alerts.loading;
    },
  },
  methods: {
    filterALertsByStatus(tabIndex) {
      this.statusFilter = this.$options.statusTabs[tabIndex].status;
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

      <gl-tabs v-if="glFeatures.alertListStatusFilteringEnabled" @input="filterALertsByStatus">
        <gl-tab v-for="tab in $options.statusTabs" :key="tab.status">
          <template slot="title">
            <span>{{ tab.title }}</span>
            <gl-badge v-if="alerts" size="sm" class="gl-tab-counter-badge">
              {{ alerts.length }}
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
        fixed
        stacked="md"
      >
        <template #cell(severity)="{ item }">
          <div class="d-inline-flex align-items-center justify-content-between">
            <gl-icon
              class="mr-2"
              :size="12"
              :name="`severity-${item.severity.toLowerCase()}`"
              :class="`icon-${item.severity.toLowerCase()}`"
            />
            {{ item.severity }}
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
          <gl-new-dropdown class="w-100" :text="item.status">
            <gl-new-dropdown-item v-for="(label, field) in $options.statuses" :key="field">
              {{ label }}
            </gl-new-dropdown-item>
          </gl-new-dropdown>
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
