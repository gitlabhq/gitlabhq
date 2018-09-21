<script>
  import _ from 'underscore';
  import { mapActions, mapGetters, mapState } from 'vuex';
  import { s__ } from '~/locale';
  import CiHeader from '~/vue_shared/components/header_ci_component.vue';
  import ErasedBlock from './erased_block.vue';
  import Sidebar from './sidebar_details_block.vue';
  import StuckBlock from './stuck_block.vue';
  import createStore from '../store';

  export default {
    name: 'JobPageApp',
    store: createStore(),
    components: {
      CiHeader,
      ErasedBlock,
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
      ...mapState(['isLoading', 'job']),
      ...mapGetters(['headerActions', 'headerTime', 'shouldRenderCalloutMessage']),
      /**
       * When job has not started the key will be `false`
       * When job started the key will be a string with a date.
       */
      jobStarted() {
        return !this.job.started === false;
      },
    },
    created() {
      this.setJobEndpoint(this.jobEndpoint);

      //this.setTraceEndpoint();

      this.fetchJob();
    },
    methods: {
      ...mapActions(['setJobEndpoint', 'setTraceEndpoint', 'setStagesEndpoint', 'fetchJob']),
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

      <erased-block
        v-if="job.erased"
        :user="job.erased_by"
        :erased-at="job.erased_at"
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
