<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getLinkedPipelinesQuery from '~/ci/pipeline_details/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stages.query.graphql';
import { formatStages } from '../utils';
import { COMMIT_BOX_POLL_INTERVAL } from '../constants';

export default {
  i18n: {
    linkedPipelinesFetchError: __('There was a problem fetching linked pipelines.'),
    stageConversionError: __('There was a problem handling the pipeline data.'),
    stagesFetchError: __('There was a problem fetching the pipeline stages.'),
  },
  components: {
    GlLoadingIcon,
    LegacyPipelineMiniGraph,
    PipelineMiniGraph,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    fullPath: {
      default: '',
    },
    iid: {
      default: '',
    },
    graphqlResourceEtag: {
      default: '',
    },
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getLinkedPipelinesQuery,
      pollInterval: COMMIT_BOX_POLL_INTERVAL,
      skip() {
        return !this.fullPath || !this.iid || this.isUsingPipelineMiniGraphQueries;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.pipeline;
      },
      error() {
        createAlert({ message: this.$options.i18n.linkedPipelinesFetchError });
      },
    },
    pipelineStages: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineStagesQuery,
      pollInterval: COMMIT_BOX_POLL_INTERVAL,
      skip() {
        return this.isUsingPipelineMiniGraphQueries;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.pipeline?.stages?.nodes || [];
      },
      error() {
        createAlert({ message: this.$options.i18n.stagesFetchError });
      },
    },
  },
  data() {
    return {
      formattedStages: [],
      pipeline: null,
      pipelineStages: [],
    };
  },
  computed: {
    downstreamPipelines() {
      const downstream = this.pipeline?.downstream?.nodes;
      return keepLatestDownstreamPipelines(downstream);
    },
    isUsingPipelineMiniGraphQueries() {
      return this.glFeatures.ciGraphqlPipelineMiniGraph;
    },
    pipelinePath() {
      return this.pipeline?.path ?? '';
    },
    upstreamPipeline() {
      return this.pipeline?.upstream;
    },
  },
  watch: {
    pipelineStages() {
      // pipelineStages are from GraphQL
      // stages are from REST
      // we do this to use dropdown_path for fetching jobs on stage click
      try {
        this.formattedStages = formatStages(this.pipelineStages, this.stages);
      } catch (error) {
        createAlert({
          message: this.$options.i18n.stageConversionError,
          captureError: true,
          error,
        });
      }
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.pipelineStages);
    toggleQueryPollingByVisibility(this.$apollo.queries.pipeline);
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="$apollo.queries.pipeline.loading" />
    <template v-else>
      <pipeline-mini-graph
        v-if="isUsingPipelineMiniGraphQueries"
        data-testid="commit-box-pipeline-mini-graph"
        :pipeline-etag="graphqlResourceEtag"
        :full-path="fullPath"
        :iid="iid"
      />
      <legacy-pipeline-mini-graph
        v-else
        data-testid="commit-box-pipeline-mini-graph"
        :downstream-pipelines="downstreamPipelines"
        :pipeline-path="pipelinePath"
        :stages="formattedStages"
        :upstream-pipeline="upstreamPipeline"
      />
    </template>
  </div>
</template>
