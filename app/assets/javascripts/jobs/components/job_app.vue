<script>
  import { mapActions, mapGetters, mapState } from 'vuex';
  import { s__ } from '~/locale';
  import CiHeader from '~/vue_shared/components/header_ci_component.vue';
  import Header from './header.vue';
  import createStore from '../store';

  export default {
    name: 'JobPageApp',
    store: createStore(),
    components: {
      CiHeader,
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
    },
    computed: {
      ...mapState(['isLoading', 'job']),
      ...mapGetters(['headerActions', 'headerTime']),
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
  <div>
    <div class="build-page">
      <gl-loading-icon v-if="isLoading" />
      <template v-else>
        <ci-header
          :status="job.status"
          :item-id="job.id"
          :time="headerTime"
          :user="job.user"
          :actions="headerActions"
          :has-sidebar-button="true"
          :should-render-triggered-label="jobStarted"
          item-name="Job"
        />
      </template>
    </div>
    <!-- sidebar -->
  </div>
</template>
