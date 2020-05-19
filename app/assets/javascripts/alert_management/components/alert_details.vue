<script>
import * as Sentry from '@sentry/browser';
import {
  GlAlert,
  GlIcon,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlSprintf,
  GlTabs,
  GlTab,
  GlButton,
} from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import query from '../graphql/queries/details.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ALERTS_SEVERITY_LABELS } from '../constants';
import updateAlertStatus from '../graphql/mutations/update_alert_status.graphql';

export default {
  statuses: {
    TRIGGERED: s__('AlertManagement|Triggered'),
    ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
    RESOLVED: s__('AlertManagement|Resolved'),
  },
  i18n: {
    errorMsg: s__(
      'AlertManagement|There was an error displaying the alert. Please refresh the page to try again.',
    ),
    fullAlertDetailsTitle: s__('AlertManagement|Full alert details'),
    overviewTitle: s__('AlertManagement|Overview'),
    reportedAt: s__('AlertManagement|Reported %{when}'),
    reportedAtWithTool: s__('AlertManagement|Reported %{when} by %{tool}'),
  },
  severityLabels: ALERTS_SEVERITY_LABELS,
  components: {
    GlAlert,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    GlDropdown,
    GlDropdownItem,
    GlTab,
    GlTabs,
    GlButton,
    TimeAgoTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    alertId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    newIssuePath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    alert: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query,
      variables() {
        return {
          fullPath: this.projectPath,
          alertId: this.alertId,
        };
      },
      update(data) {
        return data?.project?.alertManagementAlerts?.nodes?.[0] ?? null;
      },
      error(error) {
        this.errored = true;
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return { alert: null, errored: false, isErrorDismissed: false };
  },
  computed: {
    loading() {
      return this.$apollo.queries.alert.loading;
    },
    reportedAtMessage() {
      return this.alert?.monitoringTool
        ? this.$options.i18n.reportedAtWithTool
        : this.$options.i18n.reportedAt;
    },
    showErrorMsg() {
      return this.errored && !this.isErrorDismissed;
    },
  },
  methods: {
    dismissError() {
      this.isErrorDismissed = true;
    },
    updateAlertStatus(status) {
      this.$apollo
        .mutate({
          mutation: updateAlertStatus,
          variables: {
            iid: this.alertId,
            status: status.toUpperCase(),
            projectPath: this.projectPath,
          },
        })
        .catch(() => {
          createFlash(
            s__(
              'AlertManagement|There was an error while updating the status of the alert. Please try again.',
            ),
          );
        });
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="dismissError">
      {{ $options.i18n.errorMsg }}
    </gl-alert>
    <div v-if="loading"><gl-loading-icon size="lg" class="gl-mt-5" /></div>
    <div v-if="alert" class="alert-management-details gl-relative">
      <div
        class="gl-display-flex gl-justify-content-space-between gl-align-items-baseline gl-px-1 py-3 py-md-4 gl-border-b-1 gl-border-b-gray-200 gl-border-b-solid flex-column flex-sm-row"
      >
        <div
          data-testid="alert-header"
          class="gl-display-flex gl-align-items-center gl-justify-content-center"
        >
          <div
            class="gl-display-inline-flex gl-align-items-center gl-justify-content-space-between"
          >
            <gl-icon
              class="gl-mr-3 align-middle"
              :size="12"
              :name="`severity-${alert.severity.toLowerCase()}`"
              :class="`icon-${alert.severity.toLowerCase()}`"
            />
            <strong>{{ $options.severityLabels[alert.severity] }}</strong>
          </div>
          <span class="mx-2">&bull;</span>
          <span>
            <gl-sprintf :message="reportedAtMessage">
              <template #when>
                <time-ago-tooltip :time="alert.createdAt" />
              </template>
              <template #tool>{{ alert.monitoringTool }}</template>
            </gl-sprintf>
          </span>
        </div>
        <gl-button
          v-if="glFeatures.createIssueFromAlertEnabled"
          class="gl-mt-3 mt-sm-0 align-self-center align-self-sm-baseline"
          data-testid="createIssueBtn"
          :href="newIssuePath"
          category="primary"
          variant="success"
        >
          {{ s__('AlertManagement|Create issue') }}
        </gl-button>
      </div>
      <div
        v-if="alert"
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center"
      >
        <h2 data-testid="title">{{ alert.title }}</h2>
      </div>
      <gl-dropdown :text="$options.statuses[alert.status]" class="gl-absolute gl-right-0" right>
        <gl-dropdown-item
          v-for="(label, field) in $options.statuses"
          :key="field"
          data-testid="statusDropdownItem"
          class="gl-vertical-align-middle"
          @click="updateAlertStatus(label)"
        >
          <span class="d-flex">
            <gl-icon
              class="flex-shrink-0 append-right-4"
              :class="{ invisible: label.toUpperCase() !== alert.status }"
              name="mobile-issue-close"
            />
            {{ label }}
          </span>
        </gl-dropdown-item>
      </gl-dropdown>
      <gl-tabs v-if="alert" data-testid="alertDetailsTabs">
        <gl-tab data-testid="overviewTab" :title="$options.i18n.overviewTitle">
          <ul class="pl-4 mb-n1">
            <li v-if="alert.startedAt" class="my-2">
              <strong class="bold">{{ s__('AlertManagement|Start time') }}:</strong>
              <time-ago-tooltip data-testid="startTimeItem" :time="alert.startedAt" />
            </li>
            <li v-if="alert.eventCount" class="my-2">
              <strong class="bold">{{ s__('AlertManagement|Events') }}:</strong>
              <span data-testid="eventCount">{{ alert.eventCount }}</span>
            </li>
            <li v-if="alert.monitoringTool" class="my-2">
              <strong class="bold">{{ s__('AlertManagement|Tool') }}:</strong>
              <span data-testid="monitoringTool">{{ alert.monitoringTool }}</span>
            </li>
            <li v-if="alert.service" class="my-2">
              <strong class="bold">{{ s__('AlertManagement|Service') }}:</strong>
              <span data-testid="service">{{ alert.service }}</span>
            </li>
          </ul>
        </gl-tab>
        <gl-tab data-testid="fullDetailsTab" :title="$options.i18n.fullAlertDetailsTitle">
          <ul class="list-unstyled">
            <li v-for="(value, key) in alert" v-if="key !== '__typename'" :key="key">
              <p class="py-1 my-1 gl-font-base">
                <strong>{{ key }}: </strong> {{ value }}
              </p>
            </li>
          </ul>
        </gl-tab>
      </gl-tabs>
    </div>
  </div>
</template>
