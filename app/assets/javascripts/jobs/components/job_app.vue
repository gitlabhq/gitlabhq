<script>
  import _ from 'underscore';
  import { mapActions, mapGetters, mapState } from 'vuex';
  import { isScrolledToBottom } from '~/lib/utils/scroll_utils';
  import CiHeader from '~/vue_shared/components/header_ci_component.vue';
  import EmptyState from './empty_state.vue';
  import EnvironmentsBlock from './environments_block.vue';
  import ErasedBlock from './erased_block.vue';
  import LogControllers from './job_log_controllers.vue';
  import LogBlock from './job_log.vue';
  import Sidebar from './sidebar_details_block.vue';
  import StuckBlock from './stuck_block.vue';
  import createStore from '../store';

  export default {
    name: 'JobPageApp',
    store: createStore(),
    components: {
      CiHeader,
      EmptyState,
      EnvironmentsBlock,
      ErasedBlock,
      LogControllers,
      LogBlock,
      Sidebar,
      StuckBlock,
    },
    props: {
      jobEndpoint: {
        type: String,
        required: true,
      },
      traceOptions: {
        type: Object,
        required: true,
      },
      // stagesEndpoint: {
      //   type: String,
      //   required: true,
      // },
      runnerHelpUrl: {
        type: String,
        required: false,
        default: '',
      },
      terminalPath: {
        type: String,
        required: false,
        default: null,
      },
      runnersPath: {
        type: String,
        required: false,
        default: null,
      },
    },
    computed: {
      ...mapState([
        'isLoading',
        'job',
        'trace',
        'isTraceComplete',
        'traceSize',
        'isScrollingDown',
        'isTraceSizeVisible',
        'isScrollTopDisabled',
        'isScrollBottomDisabled',
        'isScrollingDown',
      ]),
      ...mapGetters(['headerActions', 'headerTime', 'shouldRenderCalloutMessage', 'jobHasTrace']),
      /**
       * When job has not started the key will be `false`
       * When job started the key will be a string with a date.
       */
      jobStarted() {
        return !this.job.started === false;
      },
      hasEnvironment() {
        return this.job.deployment_status && !_.isEmpty(this.job.deployment_status);
      },
    },
    created() {
      this.setJobEndpoint(this.jobEndpoint);

      this.setTraceOptions(this.traceOptions);

      // set traceState
      this.fetchJob();

      this.fetchTrace();
    },
    mounted() {
      window.addEventListener('scroll', this.onScroll);
    },
    destroyed() {
      window.removeEventListener('scroll', this.onScroll);
    },
    methods: {
      ...mapActions([
        'setJobEndpoint',
        'setTraceOptions',
        'setStagesEndpoint',
        'fetchJob',
        'fetchTrace',
        'scrollTop',
        'scrollBottom',
        'toggleScrollButtons',
        'toggleScrollAnimation',
      ]),
      onScroll() {
        debugger;
        if (!isScrolledToBottom()) {
          this.toggleScrollAnimation(false);
        } else if (isScrolledToBottom() && !this.isLogComplete) {
          this.toggleScrollAnimation(true);
        }

        _.throttle(this.toggleScrollButtons(), 100);
      },
    },
  };
</script>
<template>
  <div class="build-page">
    <gl-loading-icon v-if="isLoading" />

    <template v-else>
      <!-- Header Section -->
      <header>
        <div class="js-build-header build-header top-area">
          <ci-header
            :status="job.status"
            :item-id="job.id"
            :time="headerTime"
            :user="job.user"
            :actions="headerActions"
            :has-sidebar-button="true"
            :should-render-triggered-label="jobStarted"
            :item-name="__('Job')"
          />
        </div>

        <callout
          v-if="shouldRenderCalloutMessage"
          :message="job.callout_message"
        />
      </header>
      <!-- EO Header Section -->

      <!-- Body Section -->
      <stuck-block
        v-if="job.runners.available"
        :has-no-runners-for-project="job.runners.available"
        :tags="job.tag_list"
        :runners-path="runnersPath"
      />

      <environments-block
        v-if="hasEnvironment"
        :deployment-status="job.deployment_status"
      />

      <erased-block
        v-if="job.erased"
        :user="job.erased_by"
        :erased-at="job.erased_at"
      />

      <!--job log -->
      <div
        v-if="jobHasTrace"
        class="build-trace-container prepend-top-default"
      >
        <log-controllers
          :erase-path="job.erase_path"
          :raw-path="job.raw_path"
          :size="traceSize"
          :is-scroll-bottom-disabled="isScrollBottomDisabled"
          :is-scroll-top-disabled="isScrollTopDisabled"
          :is-trace-size-visible="isTraceSizeVisible"
          :is-scrolling-down="isScrollingDown"
          @scrollJobLogTop="scrollTop"
          @scrollJobLogBottom="scrollBottom"
        />

        <log-block
          :trace="trace"
          :is-complete="isTraceComplete"
        />
      </div>
      <!-- EO job log -->

      <!-- fl todo, check the illustrations not loading -->
      <empty-state
        v-else
        :illustration-path="job.status.illustration.image"
        :illustration-size-class="job.status.illustration.size"
        :title="job.status.illustration.title"
        :content="job.status.illustration.content"
        :action="job.status.action"
      />
      <!-- EO Body Section -->

      <!-- Sidebar Section -->
      <sidebar
        :job="job"
        :runner-help-url="runnerHelpUrl"
        :terminal-path="terminalPath"
      />
      <!-- EO Sidebar Section -->

    </template>
  </div>
</template>
