<script>
import { GlEmptyState, GlButton, GlLoadingIcon, GlTable, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import getAlerts from '../graphql/queries/getAlerts.query.graphql';

const tdClass = 'table-col d-flex';

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
      tdClass,
    },
    {
      key: 'start_time',
      label: s__('AlertManagement|Start Time'),
      tdClass,
    },
    {
      key: 'end_time',
      label: s__('AlertManagement|End Time'),
      tdClass,
    },
    {
      key: 'alert',
      label: s__('AlertManagement|Alert'),
      thClass: 'w-30p',
      tdClass,
    },
    {
      key: 'events',
      label: s__('AlertManagement|Events'),
      tdClass,
    },
    {
      key: 'status',
      label: s__('AlertManagement|Status'),
      tdClass,
    },
  ],
  components: {
    GlEmptyState,
    GlButton,
    GlLoadingIcon,
    GlTable,
    GlAlert,
  },
  props: {
    indexPath: {
      type: String,
      required: true,
    },
    // TODO: Handle alertManagementEnabled depending on resolution - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30024.
    alertManagementEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAlertManagementPath: {
      type: String,
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
          projectPath: this.indexPath,
        };
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

      <gl-table
        class="mt-3"
        :items="alerts"
        :fields="$options.fields"
        :show-empty="true"
        :busy="loading"
        fixed
        stacked="sm"
        tbody-tr-class="table-row mb-4"
      >
        <template #empty>
          {{ s__('AlertManagement|No alerts to display.') }}
        </template>
        <template #table-busy>
          <gl-loading-icon size="lg" color="dark" class="mt-3" />
        </template>
      </gl-table>
    </div>
    <template v-else>
      <gl-empty-state
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
            <a href="/help/user/project/operations/alert_management.html">
              {{ s__('AlertManagement|More information') }}
            </a>
          </div>
          <div class="d-block center pt-4">
            <gl-button category="primary" variant="success" :href="enableAlertManagementPath">
              {{ s__('AlertManagement|Authorize external service') }}
            </gl-button>
          </div>
        </template>
      </gl-empty-state>
    </template>
  </div>
</template>
