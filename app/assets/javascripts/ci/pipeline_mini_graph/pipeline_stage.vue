<script>
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { PIPELINE_MINI_GRAPH_POLL_INTERVAL } from '~/ci/pipeline_details/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import getPipelineStageQuery from './graphql/queries/get_pipeline_stage.query.graphql';
// import JobItem from './job_item.vue';

export default {
  i18n: {
    stageFetchError: __('There was a problem fetching the pipeline stage.'),
  },
  components: {
    // JobItem,
    CiIcon,
  },
  props: {
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelineEtag: {
      type: String,
      required: true,
    },
    pollInterval: {
      type: Number,
      required: false,
      default: PIPELINE_MINI_GRAPH_POLL_INTERVAL,
    },
    stage: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      jobs: [],
    };
  },
  apollo: {
    stage: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineStageQuery,
      pollInterval() {
        return this.pollInterval;
      },
      variables() {
        return {
          id: this.stage.id,
        };
      },
      skip() {
        // TODO: This query should occur on click
        return true;
      },
      update(data) {
        this.jobs = data?.ciPipelineStage?.jobs.nodes;
        return data?.ciPipelineStage;
      },
      error() {
        createAlert({ message: this.$options.i18n.stageFetchError });
      },
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.stage);
  },
};
</script>

<template>
  <div data-testid="pipeline-stage">
    <ci-icon
      :status="stage.detailedStatus"
      :show-tooltip="false"
      :use-link="false"
      class="gl-mb-0!"
    />
    <!-- <ul v-for="job in jobs" :key="job.id">
      <job-item :job="job" />
    </ul> -->
  </div>
</template>
