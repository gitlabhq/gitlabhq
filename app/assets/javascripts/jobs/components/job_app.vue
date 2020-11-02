<script>
import { throttle, isEmpty } from 'lodash';
import { mapGetters, mapState, mapActions } from 'vuex';
import { GlLoadingIcon, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { isScrolledToBottom } from '~/lib/utils/scroll_utils';
import { polyfillSticky } from '~/lib/utils/sticky';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import Callout from '~/vue_shared/components/callout.vue';
import EmptyState from './empty_state.vue';
import EnvironmentsBlock from './environments_block.vue';
import ErasedBlock from './erased_block.vue';
import LogTopBar from './job_log_controllers.vue';
import StuckBlock from './stuck_block.vue';
import UnmetPrerequisitesBlock from './unmet_prerequisites_block.vue';
import Sidebar from './sidebar.vue';
import { sprintf } from '~/locale';
import delayedJobMixin from '../mixins/delayed_job_mixin';
import Log from './log/log.vue';

export default {
  name: 'JobPageApp',
  components: {
    CiHeader,
    Callout,
    EmptyState,
    EnvironmentsBlock,
    ErasedBlock,
    GlIcon,
    Log,
    LogTopBar,
    StuckBlock,
    UnmetPrerequisitesBlock,
    Sidebar,
    GlLoadingIcon,
    SharedRunner: () => import('ee_component/jobs/components/shared_runner_limit_block.vue'),
  },
  directives: {
    SafeHtml,
  },
  mixins: [delayedJobMixin],
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
    variablesSettingsUrl: {
      type: String,
      required: false,
      default: null,
    },
    runnerHelpUrl: {
      type: String,
      required: false,
      default: null,
    },
    deploymentHelpUrl: {
      type: String,
      required: false,
      default: null,
    },
    terminalPath: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
    subscriptionsMoreMinutesUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState([
      'isLoading',
      'job',
      'isSidebarOpen',
      'trace',
      'isTraceComplete',
      'traceSize',
      'isTraceSizeVisible',
      'isScrollBottomDisabled',
      'isScrollTopDisabled',
      'isScrolledToBottomBeforeReceivingTrace',
      'hasError',
      'selectedStage',
    ]),
    ...mapGetters([
      'headerTime',
      'hasUnmetPrerequisitesFailure',
      'shouldRenderCalloutMessage',
      'shouldRenderTriggeredLabel',
      'hasEnvironment',
      'shouldRenderSharedRunnerLimitWarning',
      'hasTrace',
      'emptyStateIllustration',
      'isScrollingDown',
      'emptyStateAction',
      'hasRunnersForProject',
    ]),

    shouldRenderContent() {
      return !this.isLoading && !this.hasError;
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
  },
  watch: {
    // Once the job log is loaded,
    // fetch the stages for the dropdown on the sidebar
    job(newVal, oldVal) {
      if (isEmpty(oldVal) && !isEmpty(newVal.pipeline)) {
        const stages = this.job.pipeline.details.stages || [];

        const defaultStage = stages.find(stage => stage && stage.name === this.selectedStage);

        if (defaultStage) {
          this.fetchJobsForStage(defaultStage);
        }
      }

      if (newVal.archived) {
        this.$nextTick(() => {
          if (this.$refs.sticky) {
            polyfillSticky(this.$refs.sticky);
          }
        });
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
    this.stopPollingTrace();
    this.stopPolling();
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('scroll', this.updateScroll);
  },
  methods: {
    ...mapActions([
      'fetchJobsForStage',
      'hideSidebar',
      'showSidebar',
      'toggleSidebar',
      'scrollBottom',
      'scrollTop',
      'stopPollingTrace',
      'stopPolling',
      'toggleScrollButtons',
      'toggleScrollAnimation',
    ]),
    onResize() {
      this.updateSidebar();
      this.updateScroll();
    },
    updateSidebar() {
      const breakpoint = bp.getBreakpointSize();
      if (breakpoint === 'xs' || breakpoint === 'sm') {
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
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="qa-loading-animation prepend-top-20" />

    <template v-else-if="shouldRenderContent">
      <div class="build-page" data-testid="job-content">
        <!-- Header Section -->
        <header>
          <div class="build-header top-area">
            <ci-header
              :status="job.status"
              :item-id="job.id"
              :time="headerTime"
              :user="job.user"
              :has-sidebar-button="true"
              :should-render-triggered-label="shouldRenderTriggeredLabel"
              :item-name="__('Job')"
              @clickedSidebarButton="toggleSidebar"
            />
          </div>

          <callout v-if="shouldRenderHeaderCallout">
            <div v-safe-html="job.callout_message"></div>
          </callout>
        </header>
        <!-- EO Header Section -->

        <!-- Body Section -->
        <stuck-block
          v-if="job.stuck"
          :has-no-runners-for-project="hasRunnersForProject"
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
          :runners-path="runnerHelpUrl"
          :project-path="projectPath"
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
          ref="sticky"
          class="gl-mt-3 archived-job"
          :class="{ 'sticky-top border-bottom-0': hasTrace }"
          data-testid="archived-job"
        >
          <gl-icon name="lock" class="align-text-bottom" />
          {{ __('This job is archived. Only the complete pipeline can be retried.') }}
        </div>
        <!-- job log -->
        <div
          v-if="hasTrace"
          class="build-trace-container position-relative"
          :class="{ 'gl-mt-3': !job.archived }"
        >
          <log-top-bar
            :class="{
              'sidebar-expanded': isSidebarOpen,
              'sidebar-collapsed': !isSidebarOpen,
              'has-archived-block': job.archived,
            }"
            :erase-path="job.erase_path"
            :size="traceSize"
            :raw-path="job.raw_path"
            :is-scroll-bottom-disabled="isScrollBottomDisabled"
            :is-scroll-top-disabled="isScrollTopDisabled"
            :is-trace-size-visible="isTraceSizeVisible"
            :is-scrolling-down="isScrollingDown"
            @scrollJobLogTop="scrollTop"
            @scrollJobLogBottom="scrollBottom"
          />
          <log :trace="trace" :is-complete="isTraceComplete" />
        </div>
        <!-- EO job log -->

        <!-- empty state -->
        <empty-state
          v-if="!hasTrace"
          :illustration-path="emptyStateIllustration.image"
          :illustration-size-class="emptyStateIllustration.size"
          :title="emptyStateTitle"
          :content="emptyStateIllustration.content"
          :action="emptyStateAction"
          :playable="job.playable"
          :scheduled="job.scheduled"
          :variables-settings-url="variablesSettingsUrl"
        />
        <!-- EO empty state -->

        <!-- EO Body Section -->
      </div>
    </template>

    <sidebar
      v-if="shouldRenderContent"
      :class="{
        'right-sidebar-expanded': isSidebarOpen,
        'right-sidebar-collapsed': !isSidebarOpen,
      }"
      :artifact-help-url="artifactHelpUrl"
      :runner-help-url="runnerHelpUrl"
      data-testid="job-sidebar"
    />
  </div>
</template>
