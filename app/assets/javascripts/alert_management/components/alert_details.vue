<script>
import * as Sentry from '@sentry/browser';
import {
  GlAlert,
  GlLoadingIcon,
  GlNewDropdown,
  GlNewDropdownItem,
  GlTabs,
  GlTab,
  GlButton,
} from '@gitlab/ui';
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';
import query from '../graphql/queries/details.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  statuses: {
    triggered: s__('AlertManagement|Triggered'),
    acknowledged: s__('AlertManagement|Acknowledged'),
    resolved: s__('AlertManagement|Resolved'),
  },
  i18n: {
    errorMsg: s__(
      'AlertManagement|There was an error displaying the alert. Please refresh the page to try again.',
    ),
    fullAlertDetailsTitle: s__('AlertManagement|Full alert details'),
    overviewTitle: s__('AlertManagement|Overview'),
  },
  components: {
    GlAlert,
    GlLoadingIcon,
    GlNewDropdown,
    GlNewDropdownItem,
    timeAgoTooltip,
    GlTab,
    GlTabs,
    GlButton,
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
    showErrorMsg() {
      return this.errored && !this.isErrorDismissed;
    },
  },
  methods: {
    dismissError() {
      this.isErrorDismissed = true;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="dismissError">
      {{ $options.i18n.errorMsg }}
    </gl-alert>
    <div v-if="loading"><gl-loading-icon size="lg" class="mt-3" /></div>
    <div
      v-if="alert"
      class="gl-display-flex justify-content-end gl-border-b-1 gl-border-b-gray-200 gl-border-b-solid gl-p-4"
    >
      <gl-button
        v-if="glFeatures.createIssueFromAlertEnabled"
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
      <gl-new-dropdown right>
        <gl-new-dropdown-item
          v-for="(label, field) in $options.statuses"
          :key="field"
          data-testid="statusDropdownItem"
          class="align-middle"
          >{{ label }}
        </gl-new-dropdown-item>
      </gl-new-dropdown>
    </div>
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
      <gl-tab data-testid="fullDetailsTab" :title="$options.i18n.fullAlertDetailsTitle" />
    </gl-tabs>
  </div>
</template>
