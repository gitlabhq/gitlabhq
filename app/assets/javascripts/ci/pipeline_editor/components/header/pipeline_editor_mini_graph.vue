<script>
import { __ } from '~/locale';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '~/ci/pipeline_details/graphql/queries/get_linked_pipelines.query.graphql';
import { PIPELINE_FAILURE } from '../../constants';

export default {
  i18n: {
    linkedPipelinesFetchError: __('Unable to fetch upstream and downstream pipelines.'),
  },
  components: {
    LegacyPipelineMiniGraph,
  },
  inject: ['projectFullPath'],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      linkedPipelines: null,
    };
  },
  apollo: {
    linkedPipelines: {
      query: getLinkedPipelinesQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          iid: this.pipeline.iid,
        };
      },
      skip() {
        return !this.pipeline.iid;
      },
      update({ project }) {
        return project?.pipeline;
      },
      error() {
        this.$emit('showError', {
          type: PIPELINE_FAILURE,
          reasons: [this.$options.i18n.linkedPipelinesFetchError],
        });
      },
    },
  },
  computed: {
    downstreamPipelines() {
      const downstream = this.linkedPipelines?.downstream?.nodes;
      return keepLatestDownstreamPipelines(downstream);
    },
    hasPipelineStages() {
      return this.pipelineStages.length > 0;
    },
    pipelinePath() {
      return this.pipeline.detailedStatus?.detailsPath || '';
    },
    pipelineStages() {
      const stages = this.pipeline.stages?.edges;
      if (!stages) {
        return [];
      }

      return stages.map(({ node }) => {
        const { name, detailedStatus } = node;
        return {
          // TODO: fetch dropdown_path from graphql when available
          // see https://gitlab.com/gitlab-org/gitlab/-/issues/342585
          dropdown_path: `${this.pipelinePath}/stage.json?stage=${name}`,
          name,
          path: `${this.pipelinePath}#${name}`,
          status: {
            details_path: `${this.pipelinePath}#${name}`,
            has_details: detailedStatus.hasDetails,
            ...detailedStatus,
          },
          title: `${name}: ${detailedStatus.text}`,
        };
      });
    },
    upstreamPipeline() {
      return this.linkedPipelines?.upstream;
    },
  },
};
</script>

<template>
  <legacy-pipeline-mini-graph
    v-if="hasPipelineStages"
    :downstream-pipelines="downstreamPipelines"
    :pipeline-path="pipelinePath"
    :stages="pipelineStages"
    :upstream-pipeline="upstreamPipeline"
  />
</template>
