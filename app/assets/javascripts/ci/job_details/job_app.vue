<script>
import { GlLoadingIcon, GlIcon, GlAlert } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { throttle, isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState, mapActions } from 'vuex';
import JobLogTopBar from 'ee_else_ce/ci/job_details/components/job_log_top_bar.vue';
import RootCauseAnalysisButton from 'ee_else_ce/ci/job_details/components/root_cause_analysis_button.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import { isScrolledToBottom } from '~/lib/utils/scroll_utils';
import { __, sprintf } from '~/locale';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import Log from '~/ci/job_details/components/log/log.vue';
import { MANUAL_STATUS } from '~/ci/constants';
import EmptyState from './components/empty_state.vue';
import EnvironmentsBlock from './components/environments_block.vue';
import ErasedBlock from './components/erased_block.vue';
import JobHeader from './components/job_header.vue';
import StuckBlock from './components/stuck_block.vue';
import UnmetPrerequisitesBlock from './components/unmet_prerequisites_block.vue';
import Sidebar from './components/sidebar/sidebar.vue';

export default {
  name: 'JobPageApp',
  components: {
    JobHeader,
    EmptyState,
    EnvironmentsBlock,
    ErasedBlock,
    GlIcon,
    Log,
    JobLogTopBar,
    RootCauseAnalysisButton,
    StuckBlock,
    UnmetPrerequisitesBlock,
    Sidebar,
    GlLoadingIcon,
    SharedRunner: () => import('ee_component/ci/runner/components/shared_runner_limit_block.vue'),
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  mixins: [delayedJobMixin, glAbilitiesMixin()],
  props: {
    artifactHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
    runnerSettingsUrl: {
      type: String,
      required: false,
      default: null,
    },
    deploymentHelpUrl: {
      type: String,
      required: false,
      default: null,
    },
    subscriptionsMoreMinutesUrl: {
      type: String,
      required: false,
      default: null,
    },
    logViewerPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchResults: [],
      showUpdateVariablesState: false,
    };
  },
  computed: {
    ...mapState([
      'isLoading',
      'job',
      'isSidebarOpen',
      'jobLog',
      'isJobLogComplete',
      'jobLogSize',
      'isJobLogSizeVisible',
      'isScrollBottomDisabled',
      'isScrollTopDisabled',
      'hasError',
      'selectedStage',
      'fullScreenEnabled',
    ]),
    ...mapGetters([
      'headerTime',
      'hasUnmetPrerequisitesFailure',
      'shouldRenderCalloutMessage',
      'shouldRenderTriggeredLabel',
      'hasEnvironment',
      'shouldRenderSharedRunnerLimitWarning',
      'hasJobLog',
      'emptyStateIllustration',
      'isScrollingDown',
      'emptyStateAction',
      'hasOfflineRunnersForProject',
      'fullScreenAPIAndContainerAvailable',
    ]),

    shouldRenderContent() {
      return (!this.isLoading && !this.hasError) || this.hasJobLog;
    },

    emptyStateTitle() {
      const { emptyStateIllustration, remainingTime } = this;
      const { title } = emptyStateIllustration;

      if (this.isDelayedJob) {
        return sprintf(title, { remainingTime });
      }

      return title;
    },

    shouldRenderHeaderCallout() {
      return this.shouldRenderCalloutMessage && !this.hasUnmetPrerequisitesFailure;
    },

    isJobRetryable() {
      return Boolean(this.job.retry_path);
    },

    jobName() {
      return sprintf(__('%{jobName}'), { jobName: this.job.name });
    },
    jobConfirmationMessage() {
      return this.job.status?.action?.confirmation_message;
    },
  },
  watch: {
    // Once the job log is loaded,
    // fetch the stages for the dropdown on the sidebar
    job(newVal, oldVal) {
      if (isEmpty(oldVal) && !isEmpty(newVal.pipeline)) {
        const stages = this.job.pipeline.details.stages || [];

        const defaultStage = stages.find((stage) => stage && stage.name === this.selectedStage);

        if (defaultStage) {
          this.fetchJobsForStage(defaultStage);
        }
      }

      // Only poll for job log if we are not in the manual variables form empty state.
      // This will be handled more elegantly in the future with GraphQL in https://gitlab.com/gitlab-org/gitlab/-/issues/389597
      if (newVal?.status?.group !== MANUAL_STATUS && !this.showUpdateVariablesState) {
        this.fetchJobLog();
      }
    },
  },
  created() {
    this.throttled = throttle(this.toggleScrollButtons, 100);

    window.addEventListener('resize', this.onResize);
    window.addEventListener('scroll', this.updateScroll);
  },
  mounted() {
    this.updateSidebar();
  },
  beforeDestroy() {
    this.stopPollingJobLog();
    this.stopPolling();
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('scroll', this.updateScroll);
  },
  methods: {
    ...mapActions([
      'fetchJobLog',
      'fetchJobsForStage',
      'hideSidebar',
      'showSidebar',
      'toggleSidebar',
      'scrollBottom',
      'scrollTop',
      'stopPollingJobLog',
      'stopPolling',
      'toggleScrollButtons',
      'toggleScrollAnimation',
      'enterFullscreen',
      'exitFullscreen',
    ]),
    onHideManualVariablesForm() {
      this.showUpdateVariablesState = false;
    },
    onResize() {
      this.updateSidebar();
      this.updateScroll();
    },
    onUpdateVariables() {
      this.showUpdateVariablesState = true;
    },
    updateSidebar() {
      const breakpoint = bp.getBreakpointSize();
      if (breakpoint === 'xs' || breakpoint === 'sm' || breakpoint === 'md') {
        this.hideSidebar();
      } else if (!this.isSidebarOpen) {
        this.showSidebar();
      }
    },
    updateScroll() {
      if (!isScrolledToBottom()) {
        this.toggleScrollAnimation(false);
      } else if (this.isScrollingDown) {
        this.toggleScrollAnimation(true);
      }

      this.throttled();
    },
    setSearchResults(searchResults) {
      this.searchResults = searchResults;
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-6" />

    <template v-else-if="shouldRenderContent">
      <div class="build-page" data-testid="job-content">
        <!-- Header Section -->
        <header>
          <job-header
            :status="job.status"
            :time="headerTime"
            :user="job.user"
            :should-render-triggered-label="shouldRenderTriggeredLabel"
            :name="jobName"
            @clickedSidebarButton="toggleSidebar"
          />
          <gl-alert
            v-if="shouldRenderHeaderCallout"
            variant="danger"
            class="gl-mt-3"
            :dismissible="false"
          >
            <div v-safe-html="job.callout_message"></div>
          </gl-alert>
        </header>
        <!-- EO Header Section -->

        <!-- Body Section -->
        <stuck-block
          v-if="job.stuck"
          :has-offline-runners-for-project="hasOfflineRunnersForProject"
          :tags="job.tags"
          :runners-path="runnerSettingsUrl"
        />

        <unmet-prerequisites-block
          v-if="hasUnmetPrerequisitesFailure"
          :help-path="deploymentHelpUrl"
        />

        <shared-runner
          v-if="shouldRenderSharedRunnerLimitWarning"
          :quota-used="job.runners.quota.used"
          :quota-limit="job.runners.quota.limit"
          :subscriptions-more-minutes-url="subscriptionsMoreMinutesUrl"
        />

        <environments-block
          v-if="hasEnvironment"
          :deployment-status="job.deployment_status"
          :deployment-cluster="job.deployment_cluster"
          :icon-status="job.status"
        />

        <erased-block
          v-if="job.erased_at"
          data-testid="job-erased-block"
          :user="job.erased_by"
          :erased-at="job.erased_at"
        />

        <div
          v-if="job.archived"
          class="archived-job gl-z-1 gl-m-auto gl-mt-3 gl-items-center gl-px-3 gl-py-2"
          :class="{ 'sticky-top gl-border-b-0': hasJobLog }"
          data-testid="archived-job"
        >
          <gl-icon name="lock" class="gl-align-bottom" />
          {{ __('This job is archived. Only the complete pipeline can be retried.') }}
        </div>
        <!-- job log -->
        <div v-if="hasJobLog && !showUpdateVariablesState" class="build-log-container gl-relative">
          <job-log-top-bar
            :class="{
              'has-archived-block': job.archived,
            }"
            :size="jobLogSize"
            :raw-path="job.raw_path"
            :log-viewer-path="logViewerPath"
            :is-scroll-bottom-disabled="isScrollBottomDisabled"
            :is-scroll-top-disabled="isScrollTopDisabled"
            :is-job-log-size-visible="isJobLogSizeVisible"
            :is-scrolling-down="isScrollingDown"
            :is-complete="isJobLogComplete"
            :job-log="jobLog"
            :full-screen-mode-available="fullScreenAPIAndContainerAvailable"
            :full-screen-enabled="fullScreenEnabled"
            @scrollJobLogTop="scrollTop"
            @scrollJobLogBottom="scrollBottom"
            @searchResults="setSearchResults"
            @enterFullscreen="enterFullscreen"
            @exitFullscreen="exitFullscreen"
          />

          <log :search-results="searchResults" />

          <root-cause-analysis-button
            :job-id="job.id"
            :job-status-group="job.status.group"
            :can-troubleshoot-job="glAbilities.troubleshootJobWithAi"
          />
        </div>
        <!-- EO job log -->

        <!-- empty state -->
        <empty-state
          v-if="!hasJobLog || showUpdateVariablesState"
          :illustration-path="emptyStateIllustration.image"
          :illustration-size-class="emptyStateIllustration.size"
          :is-retryable="isJobRetryable"
          :job-id="job.id"
          :job-name="jobName"
          :title="emptyStateTitle"
          :confirmation-message="jobConfirmationMessage"
          :content="emptyStateIllustration.content"
          :action="emptyStateAction"
          :playable="job.playable"
          :scheduled="job.scheduled"
          @hideManualVariablesForm="onHideManualVariablesForm()"
        />
        <!-- EO empty state -->

        <!-- EO Body Section -->

        <sidebar
          :class="{
            'right-sidebar-expanded': isSidebarOpen,
            'right-sidebar-collapsed': !isSidebarOpen,
          }"
          :artifact-help-url="artifactHelpUrl"
          data-testid="job-sidebar"
          @updateVariables="onUpdateVariables()"
        />
      </div>
    </template>
  </div>
</template>
