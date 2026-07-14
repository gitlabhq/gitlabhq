<script>
import { GlAlert, GlBadge, GlIcon, GlLink, GlSprintf, GlTabs, GlTab, GlButton } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';
import { fetchPolicies } from '~/lib/graphql';
import { toggleContainerClasses } from '~/lib/utils/dom_utils';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import MetricImagesTab from '~/vue_shared/components/metric_images/metric_images_tab.vue';
import { PAGE_CONFIG, SEVERITY_LEVELS } from '../constants';
import createIssueMutation from '../graphql/mutations/alert_issue_create.mutation.graphql';
import alertQuery from '../graphql/queries/alert_sidebar_details.query.graphql';
import AlertSidebar from './alert_sidebar.vue';
import AlertTodo from './alert_todo.vue';
import AlertSummaryRow from './alert_summary_row.vue';
import SystemNote from './system_notes/system_note.vue';

const containerEl = document.querySelector('.layout-page');

export default {
  name: 'AlertDetails',
  i18n: {
    errorMsg: s__(
      'AlertManagement|There was an error displaying the alert. Please refresh the page to try again.',
    ),
    reportedAt: s__('AlertManagement|Reported %{when}'),
    reportedAtWithTool: s__('AlertManagement|Reported %{when} by %{tool}'),
  },
  directives: {
    SafeHtml,
  },
  severityLabels: SEVERITY_LEVELS,
  tabsConfig: [
    {
      id: 'overview',
      title: s__('AlertManagement|Alert details'),
    },
    {
      id: 'metrics',
      title: s__('AlertManagement|Metrics'),
    },
    {
      id: 'activity',
      title: s__('AlertManagement|Activity feed'),
    },
  ],
  components: {
    AlertDetailsTable,
    AlertSummaryRow,
    DetailLayout,
    GlBadge,
    GlAlert,
    GlIcon,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
    GlButton,
    TimeAgoTooltip,
    AlertSidebar,
    AlertTodo,
    SystemNote,
    MetricImagesTab,
  },
  inject: {
    projectPath: {
      default: '',
    },
    alertId: {
      default: '',
    },
    projectIssuesPath: {
      default: '',
    },
    statuses: {
      default: PAGE_CONFIG.OPERATIONS.STATUSES,
    },
    trackAlertsDetailsViewsOptions: {
      default: null,
    },
  },
  apollo: {
    alert: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: alertQuery,
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
    return {
      alert: null,
      errored: false,
      isErrorDismissed: false,
      createIncidentError: '',
      incidentCreationInProgress: false,
      sidebarErrorMessage: '',
    };
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
    activeTab() {
      return this.$route.params.tabId || this.$options.tabsConfig[0].id;
    },
    currentTabIndex: {
      get() {
        const tabIndex = this.$options.tabsConfig.findIndex((tab) => tab.id === this.activeTab);
        return tabIndex >= 0 ? tabIndex : 0;
      },
      set(tabIdx) {
        const tabId = this.$options.tabsConfig[tabIdx].id;
        if (this.$route.params?.tabId !== tabId) {
          this.$router.push({ name: 'tab', params: { tabId } });
        }
      },
    },
    environmentName() {
      return this.alert?.environment?.name;
    },
    environmentPath() {
      return this.alert?.environment?.path;
    },
  },
  mounted() {
    if (this.trackAlertsDetailsViewsOptions) {
      this.trackPageViews();
    }
    toggleContainerClasses(containerEl, {
      'issuable-bulk-update-sidebar': true,
    });
  },
  updated() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
    });
  },
  methods: {
    dismissError() {
      this.isErrorDismissed = true;
      this.sidebarErrorMessage = '';
    },
    handleAlertSidebarError(errorMessage) {
      this.errored = true;
      this.sidebarErrorMessage = errorMessage;
    },
    createIncident() {
      this.incidentCreationInProgress = true;

      this.$apollo
        .mutate({
          mutation: createIssueMutation,
          variables: {
            iid: this.alert.iid,
            projectPath: this.projectPath,
          },
        })
        .then(
          ({
            data: {
              createAlertIssue: { errors, issue },
            },
          }) => {
            if (errors?.length) {
              [this.createIncidentError] = errors;
              this.incidentCreationInProgress = false;
            } else if (issue) {
              visitUrl(this.incidentPath(issue.iid));
            }
          },
        )
        .catch((error) => {
          this.createIncidentError = error;
          this.incidentCreationInProgress = false;
        });
    },
    incidentPath(issueId) {
      return joinPaths(this.projectIssuesPath, 'incident', issueId);
    },
    trackPageViews() {
      const { category, action } = this.trackAlertsDetailsViewsOptions;
      Tracking.event(category, action);
    },
  },
};
</script>

<template>
  <detail-layout :loading="loading" :heading="alert ? alert.title : null">
    <template v-if="alert" #description>
      <gl-badge class="gl-mr-2">
        <strong>{{ s__('AlertManagement|Alert') }}</strong>
      </gl-badge>
      <gl-sprintf :message="reportedAtMessage">
        <template #when>
          <time-ago-tooltip :time="alert.createdAt" />
        </template>
        <template #tool>{{ alert.monitoringTool }}</template>
      </gl-sprintf>
    </template>

    <template v-if="alert" #actions>
      <alert-todo
        :project-path="projectPath"
        :alert="alert"
        @alert-error="handleAlertSidebarError"
      />
      <gl-button
        v-if="alert.issue"
        data-testid="view-incident-button"
        :href="incidentPath(alert.issue.iid)"
        category="primary"
        variant="confirm"
      >
        {{ s__('AlertManagement|View incident') }}
      </gl-button>
      <gl-button
        v-else
        data-testid="create-incident-button"
        :loading="incidentCreationInProgress"
        category="primary"
        variant="confirm"
        @click="createIncident()"
      >
        {{ s__('AlertManagement|Create incident') }}
      </gl-button>
    </template>

    <template v-if="showErrorMsg || createIncidentError" #alerts>
      <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="dismissError">
        <p v-safe-html="sidebarErrorMessage || $options.i18n.errorMsg"></p>
      </gl-alert>
      <gl-alert
        v-if="createIncidentError"
        variant="danger"
        data-testid="incident-creation-error"
        @dismiss="createIncidentError = null"
      >
        {{ createIncidentError }}
      </gl-alert>
    </template>

    <template #sidebar>
      <alert-sidebar v-if="alert" :alert="alert" @alert-error="handleAlertSidebarError" />
    </template>

    <gl-tabs v-if="alert" v-model="currentTabIndex" data-testid="alert-details-tabs">
      <gl-tab :data-testid="$options.tabsConfig[0].id" :title="$options.tabsConfig[0].title">
        <alert-summary-row v-if="alert.severity" :label="`${s__('AlertManagement|Severity')}:`">
          <span data-testid="severity">
            <gl-icon
              class="gl-align-middle"
              :size="12"
              :name="`severity-${alert.severity.toLowerCase()}`"
              :class="`icon-${alert.severity.toLowerCase()}`"
            />
            {{ $options.severityLabels[alert.severity] }}
          </span>
        </alert-summary-row>
        <alert-summary-row v-if="environmentName" :label="`${s__('AlertManagement|Environment')}:`">
          <gl-link
            v-if="environmentPath"
            class="gl-inline-block"
            data-testid="environment-path"
            :href="environmentPath"
          >
            {{ environmentName }}
          </gl-link>
          <span v-else data-testid="environment-name">{{ environmentName }}</span>
        </alert-summary-row>
        <alert-summary-row v-if="alert.startedAt" :label="`${s__('AlertManagement|Start time')}:`">
          <time-ago-tooltip data-testid="start-time-item" :time="alert.startedAt" />
        </alert-summary-row>
        <alert-summary-row
          v-if="alert.eventCount"
          :label="`${s__('AlertManagement|Events')}:`"
          data-testid="event-count"
        >
          {{ alert.eventCount }}
        </alert-summary-row>
        <alert-summary-row
          v-if="alert.monitoringTool"
          :label="`${s__('AlertManagement|Tool')}:`"
          data-testid="monitoring-tool"
        >
          {{ alert.monitoringTool }}
        </alert-summary-row>
        <alert-summary-row
          v-if="alert.service"
          :label="`${s__('AlertManagement|Service')}:`"
          data-testid="service"
        >
          {{ alert.service }}
        </alert-summary-row>
        <alert-summary-row
          v-if="alert.runbook"
          :label="`${s__('AlertManagement|Runbook')}:`"
          data-testid="runbook"
        >
          {{ alert.runbook }}
        </alert-summary-row>
        <alert-details-table :alert="alert" :loading="loading" :statuses="statuses" />
      </gl-tab>

      <gl-tab :title="$options.tabsConfig[1].title">
        <metric-images-tab :data-testid="$options.tabsConfig[1].id" />
      </gl-tab>

      <gl-tab :data-testid="$options.tabsConfig[2].id" :title="$options.tabsConfig[2].title">
        <div v-if="alert.notes.nodes.length > 0" class="issuable-discussion">
          <ul class="notes main-notes-list timeline">
            <system-note v-for="note in alert.notes.nodes" :key="note.id" :note="note" />
          </ul>
        </div>
      </gl-tab>
    </gl-tabs>
  </detail-layout>
</template>
