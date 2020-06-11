<script>
import * as Sentry from '@sentry/browser';
import {
  GlAlert,
  GlBadge,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
  GlTabs,
  GlTab,
  GlButton,
  GlTable,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import query from '../graphql/queries/details.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ALERTS_SEVERITY_LABELS, trackAlertsDetailsViewsOptions } from '../constants';
import createIssueQuery from '../graphql/mutations/create_issue_from_alert.graphql';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import { toggleContainerClasses } from '~/lib/utils/dom_utils';
import AlertSidebar from './alert_sidebar.vue';

const containerEl = document.querySelector('.page-with-contextual-sidebar');

export default {
  i18n: {
    errorMsg: s__(
      'AlertManagement|There was an error displaying the alert. Please refresh the page to try again.',
    ),
    fullAlertDetailsTitle: s__('AlertManagement|Alert details'),
    overviewTitle: s__('AlertManagement|Overview'),
    reportedAt: s__('AlertManagement|Reported %{when}'),
    reportedAtWithTool: s__('AlertManagement|Reported %{when} by %{tool}'),
  },
  severityLabels: ALERTS_SEVERITY_LABELS,
  components: {
    GlBadge,
    GlAlert,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    GlTab,
    GlTabs,
    GlButton,
    GlTable,
    TimeAgoTooltip,
    AlertSidebar,
  },
  props: {
    alertId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    projectIssuesPath: {
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
    return {
      alert: null,
      errored: false,
      isErrorDismissed: false,
      createIssueError: '',
      issueCreationInProgress: false,
      sidebarCollapsed: false,
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
  },
  mounted() {
    this.trackPageViews();
    toggleContainerClasses(containerEl, {
      'issuable-bulk-update-sidebar': true,
      'right-sidebar-expanded': true,
    });
  },
  methods: {
    dismissError() {
      this.isErrorDismissed = true;
      this.sidebarErrorMessage = '';
    },
    toggleSidebar() {
      this.sidebarCollapsed = !this.sidebarCollapsed;
      toggleContainerClasses(containerEl, {
        'right-sidebar-collapsed': this.sidebarCollapsed,
        'right-sidebar-expanded': !this.sidebarCollapsed,
      });
    },
    handleAlertSidebarError(errorMessage) {
      this.errored = true;
      this.sidebarErrorMessage = errorMessage;
    },
    createIssue() {
      this.issueCreationInProgress = true;

      this.$apollo
        .mutate({
          mutation: createIssueQuery,
          variables: {
            iid: this.alert.iid,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { createAlertIssue: { errors, issue } } }) => {
          if (errors?.length) {
            [this.createIssueError] = errors;
            this.issueCreationInProgress = false;
          } else if (issue) {
            visitUrl(this.issuePath(issue.iid));
          }
        })
        .catch(error => {
          this.createIssueError = error;
          this.issueCreationInProgress = false;
        });
    },
    issuePath(issueId) {
      return joinPaths(this.projectIssuesPath, issueId);
    },
    trackPageViews() {
      const { category, action } = trackAlertsDetailsViewsOptions;
      Tracking.event(category, action);
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="dismissError">
      {{ sidebarErrorMessage || $options.i18n.errorMsg }}
    </gl-alert>
    <gl-alert
      v-if="createIssueError"
      variant="danger"
      data-testid="issueCreationError"
      @dismiss="createIssueError = null"
    >
      {{ createIssueError }}
    </gl-alert>
    <div v-if="loading"><gl-loading-icon size="lg" class="gl-mt-5" /></div>
    <div
      v-if="alert"
      class="alert-management-details gl-relative"
      :class="{ 'pr-8': sidebarCollapsed }"
    >
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
            <gl-badge class="gl-mr-3">
              <strong>{{ s__('AlertManagement|Alert') }}</strong>
            </gl-badge>
          </div>
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
          v-if="alert.issueIid"
          class="gl-mt-3 mt-sm-0 align-self-center align-self-sm-baseline alert-details-issue-button"
          data-testid="viewIssueBtn"
          :href="issuePath(alert.issueIid)"
          category="primary"
          variant="success"
        >
          {{ s__('AlertManagement|View issue') }}
        </gl-button>
        <gl-button
          v-else
          class="gl-mt-3 mt-sm-0 align-self-center align-self-sm-baseline alert-details-issue-button"
          data-testid="createIssueBtn"
          :loading="issueCreationInProgress"
          category="primary"
          variant="success"
          @click="createIssue()"
        >
          {{ s__('AlertManagement|Create issue') }}
        </gl-button>
        <gl-button
          :aria-label="__('Toggle sidebar')"
          category="primary"
          variant="default"
          class="d-sm-none gl-absolute toggle-sidebar-mobile-button"
          type="button"
          @click="toggleSidebar"
        >
          <i class="fa fa-angle-double-left"></i>
        </gl-button>
      </div>
      <div
        v-if="alert"
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center"
      >
        <h2 data-testid="title">{{ alert.title }}</h2>
      </div>
      <gl-tabs v-if="alert" data-testid="alertDetailsTabs">
        <gl-tab data-testid="overviewTab" :title="$options.i18n.overviewTitle">
          <div v-if="alert.severity" class="gl-mt-3 gl-mb-5 gl-display-flex">
            <div class="gl-font-weight-bold gl-w-13 gl-text-right gl-pr-3">
              {{ s__('AlertManagement|Severity') }}:
            </div>
            <div class="gl-pl-2" data-testid="severity">
              <span>
                <gl-icon
                  class="gl-vertical-align-middle"
                  :size="12"
                  :name="`severity-${alert.severity.toLowerCase()}`"
                  :class="`icon-${alert.severity.toLowerCase()}`"
                />
              </span>
              {{ $options.severityLabels[alert.severity] }}
            </div>
          </div>
          <div v-if="alert.startedAt" class="gl-my-5 gl-display-flex">
            <div class="gl-font-weight-bold gl-w-13 gl-text-right gl-pr-3">
              {{ s__('AlertManagement|Start time') }}:
            </div>
            <div class="gl-pl-2">
              <time-ago-tooltip data-testid="startTimeItem" :time="alert.startedAt" />
            </div>
          </div>
          <div v-if="alert.eventCount" class="gl-my-5 gl-display-flex">
            <div class="gl-font-weight-bold gl-w-13 gl-text-right gl-pr-3">
              {{ s__('AlertManagement|Events') }}:
            </div>
            <div class="gl-pl-2" data-testid="eventCount">{{ alert.eventCount }}</div>
          </div>
          <div v-if="alert.monitoringTool" class="gl-my-5 gl-display-flex">
            <div class="gl-font-weight-bold gl-w-13 gl-text-right gl-pr-3">
              {{ s__('AlertManagement|Tool') }}:
            </div>
            <div class="gl-pl-2" data-testid="monitoringTool">{{ alert.monitoringTool }}</div>
          </div>
          <div v-if="alert.service" class="gl-my-5 gl-display-flex">
            <div class="bold gl-w-13 gl-text-right gl-pr-3">
              {{ s__('AlertManagement|Service') }}:
            </div>
            <div class="gl-pl-2" data-testid="service">{{ alert.service }}</div>
          </div>
        </gl-tab>
        <gl-tab data-testid="fullDetailsTab" :title="$options.i18n.fullAlertDetailsTitle">
          <gl-table
            class="alert-management-details-table"
            :items="[{ key: 'Value', ...alert }]"
            :show-empty="true"
            :busy="loading"
            stacked
          >
            <template #empty>
              {{ s__('AlertManagement|No alert data to display.') }}
            </template>
            <template #table-busy>
              <gl-loading-icon size="lg" color="dark" class="mt-3" />
            </template>
          </gl-table>
        </gl-tab>
      </gl-tabs>
      <alert-sidebar
        :project-path="projectPath"
        :alert="alert"
        :sidebar-collapsed="sidebarCollapsed"
        @toggle-sidebar="toggleSidebar"
        @alert-sidebar-error="handleAlertSidebarError"
      />
    </div>
  </div>
</template>
