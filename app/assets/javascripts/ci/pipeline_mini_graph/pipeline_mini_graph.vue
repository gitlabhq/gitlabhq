<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import { PIPELINE_MINI_GRAPH_POLL_INTERVAL } from '~/ci/pipeline_details/constants';
import getLinkedPipelinesQuery from '~/ci/pipeline_details/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from './graphql/queries/get_pipeline_stages.query.graphql';
import LegacyPipelineMiniGraph from './legacy_pipeline_mini_graph.vue';

export default {
  i18n: {
    linkedPipelinesFetchError: __('There was a problem fetching linked pipelines.'),
    stagesFetchError: __('There was a problem fetching the pipeline stages.'),
  },
  components: {
    GlLoadingIcon,
    LegacyPipelineMiniGraph,
  },
  props: {
    pipelineEtag: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
    pollInterval: {
      type: Number,
      required: false,
      default: PIPELINE_MINI_GRAPH_POLL_INTERVAL,
    },
  },
  data() {
    return {
      linkedPipelines: null,
      pipelineStages: [],
    };
  },
  apollo: {
    linkedPipelines: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getLinkedPipelinesQuery,
      pollInterval() {
        return this.pollInterval;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.pipeline || this.linkedpipelines;
      },
      error() {
        createAlert({ message: this.$options.i18n.linkedPipelinesFetchError });
      },
    },
    pipelineStages: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineStagesQuery,
      pollInterval() {
        return this.pollInterval;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.pipeline?.stages?.nodes || this.pipelineStages;
      },
      error() {
        createAlert({ message: this.$options.i18n.stagesFetchError });
      },
    },
  },
  computed: {
    downstreamPipelines() {
      return keepLatestDownstreamPipelines(this.linkedPipelines?.downstream?.nodes);
    },
    formattedStages() {
      return this.pipelineStages.map((stage) => {
        const { name, detailedStatus } = stage;
        return {
          // TODO: Once we fetch stage by ID with GraphQL,
          // this method will change.
          // see https://gitlab.com/gitlab-org/gitlab/-/issues/384853
          id: stage.id,
          dropdown_path: `${this.pipelinePath}/stage.json?stage=${name}`,
          name,
          path: `${this.pipelinePath}#${name}`,
          status: {
            details_path: `${this.pipelinePath}#${name}`,
            has_details: detailedStatus?.hasDetails || false,
            ...detailedStatus,
          },
          title: `${name}: ${detailedStatus?.text || ''}`,
        };
      });
    },
    pipelinePath() {
      return this.linkedPipelines?.path || '';
    },
    upstreamPipeline() {
      return this.linkedPipelines?.upstream;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.linkedPipelines);
    toggleQueryPollingByVisibility(this.$apollo.queries.pipelineStages);
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="$apollo.queries.pipelineStages.loading" />
    <legacy-pipeline-mini-graph
      v-else
      data-testid="pipeline-mini-graph"
      is-graphql
      :downstream-pipelines="downstreamPipelines"
      :is-merge-train="isMergeTrain"
      :pipeline-path="pipelinePath"
      :stages="formattedStages"
      :upstream-pipeline="upstreamPipeline"
    />
  </div>
</template>
