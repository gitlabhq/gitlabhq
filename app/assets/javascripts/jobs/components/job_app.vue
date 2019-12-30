<script>
import _ from 'underscore';
import { mapGetters, mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { isScrolledToBottom } from '~/lib/utils/scroll_utils';
import { polyfillSticky } from '~/lib/utils/sticky';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import Callout from '~/vue_shared/components/callout.vue';
import Icon from '~/vue_shared/components/icon.vue';
import createStore from '../store';
import EmptyState from './empty_state.vue';
import EnvironmentsBlock from './environments_block.vue';
import ErasedBlock from './erased_block.vue';
import LogTopBar from './job_log_controllers.vue';
import StuckBlock from './stuck_block.vue';
import UnmetPrerequisitesBlock from './unmet_prerequisites_block.vue';
import Sidebar from './sidebar.vue';
import { sprintf } from '~/locale';
import delayedJobMixin from '../mixins/delayed_job_mixin';
import { isNewJobLogActive } from '../store/utils';

export default {
  name: 'JobPageApp',
  store: createStore(),
  components: {
    CiHeader,
    Callout,
    EmptyState,
    EnvironmentsBlock,
    ErasedBlock,
    Icon,
    Log: () => (isNewJobLogActive() ? import('./log/log.vue') : import('./job_log.vue')),
    LogTopBar,
    StuckBlock,
    UnmetPrerequisitesBlock,
    Sidebar,
    GlLoadingIcon,
    SharedRunner: () => import('ee_component/jobs/components/shared_runner_limit_block.vue'),
  },
  mixins: [delayedJobMixin],
  props: {
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
    endpoint: {
      type: String,
      required: true,
    },
    terminalPath: {
      type: String,
      required: false,
      default: null,
    },
    pagePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    logState: {
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
      if (_.isEmpty(oldVal) && !_.isEmpty(newVal.pipeline)) {
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
    this.throttled = _.throttle(this.toggleScrollButtons, 100);

    this.setJobEndpoint(this.endpoint);
    this.setTraceOptions({
      logState: this.logState,
      pagePath: this.pagePath,
    });

    this.fetchJob();
    this.fetchTrace();

    window.addEventListener('resize', this.onResize);
    window.addEventListener('scroll', this.updateScroll);
  },
  mounted() {
    this.updateSidebar();
  },
  destroyed() {
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('scroll', this.updateScroll);
  },
  methods: {
    ...mapActions([
      'setJobEndpoint',
      'setTraceOptions',
      'fetchJob',
      'fetchJobsForStage',
      'hideSidebar',
      'showSidebar',
      'toggleSidebar',
      'fetchTrace',
      'scrollBottom',
      'scrollTop',
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
    <gl-loading-icon
      v-if="isLoading"
      :size="2"
      class="js-job-loading qa-loading-animation prepend-top-20"
    />

    <template v-else-if="shouldRenderContent">
      <div class="js-job-content build-page">
        <!-- Header Section -->
        <header>
          <div class="js-build-header build-header top-area">
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
            <div v-html="job.callout_message"></div>
          </callout>
        </header>
        <!-- EO Header Section -->

        <!-- Body Section -->
        <stuck-block
          v-if="job.stuck"
          class="js-job-stuck"
          :has-no-runners-for-project="hasRunnersForProject"
          :tags="job.tags"
          :runners-path="runnerSettingsUrl"
        />

        <unmet-prerequisites-block
          v-if="hasUnmetPrerequisitesFailure"
          class="js-job-failed"
          :help-path="deploymentHelpUrl"
        />

        <shared-runner
          v-if="shouldRenderSharedRunnerLimitWarning"
          class="js-shared-runner-limit"
          :quota-used="job.runners.quota.used"
          :quota-limit="job.runners.quota.limit"
          :runners-path="runnerHelpUrl"
          :project-path="projectPath"
          :subscriptions-more-minutes-url="subscriptionsMoreMinutesUrl"
        />

        <environments-block
          v-if="hasEnvironment"
          class="js-job-environment"
          :deployment-status="job.deployment_status"
          :icon-status="job.status"
        />

        <erased-block
          v-if="job.erased_at"
          class="js-job-erased-block"
          :user="job.erased_by"
          :erased-at="job.erased_at"
        />

        <div
          v-if="job.archived"
          ref="sticky"
          class="js-archived-job prepend-top-default archived-job"
          :class="{ 'sticky-top border-bottom-0': hasTrace }"
        >
          <icon name="lock" class="align-text-bottom" />
          {{ __('This job is archived. Only the complete pipeline can be retried.') }}
        </div>
        <!-- job log -->
        <div
          v-if="hasTrace"
          class="build-trace-container position-relative"
          :class="{ 'prepend-top-default': !job.archived }"
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
          class="js-job-empty-state"
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
      class="js-job-sidebar"
      :class="{
        'right-sidebar-expanded': isSidebarOpen,
        'right-sidebar-collapsed': !isSidebarOpen,
      }"
      :runner-help-url="runnerHelpUrl"
    />
  </div>
</template>
