<script>
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { PIPELINE_MINI_GRAPH_POLL_INTERVAL } from '~/ci/pipeline_details/constants';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import getPipelineStageQuery from './graphql/queries/get_pipeline_stage.query.graphql';
import JobItem from './job_item.vue';

export default {
  i18n: {
    stageFetchError: __('There was a problem fetching the pipeline stage.'),
  },

  components: {
    JobItem,
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
    stageId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      jobs: [],
      stage: null,
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
          id: this.stageId,
        };
      },
      skip() {
        return !this.stageId;
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
    <ul v-for="job in jobs" :key="job.id">
      <job-item :job="job" />
    </ul>
  </div>
</template>
