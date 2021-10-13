<script>
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';

export default {
  components: {
    PipelineMiniGraph,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
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
  },
};
</script>

<template>
  <div v-if="pipelineStages.length > 0" class="stage-cell gl-mr-5">
    <pipeline-mini-graph class="gl-display-inline" :stages="pipelineStages" />
  </div>
</template>
