<script>
import { __ } from '~/locale';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import { PIPELINE_FAILURE } from '../../constants';

export default {
  i18n: {
    linkedPipelinesFetchError: __('Unable to fetch upstream and downstream pipelines.'),
  },
  components: {
    PipelineMiniGraph,
    LinkedPipelinesMiniList: () =>
      import('ee_component/vue_shared/components/linked_pipelines_mini_list.vue'),
  },
  inject: ['projectFullPath'],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
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
      return this.linkedPipelines?.downstream?.nodes || [];
    },
    hasDownstreamPipelines() {
      return this.downstreamPipelines.length > 0;
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
  <div
    v-if="hasPipelineStages"
    class="gl-align-items-center gl-display-inline-flex gl-flex-wrap stage-cell gl-mr-5"
  >
    <linked-pipelines-mini-list
      v-if="upstreamPipeline"
      :triggered-by="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
        upstreamPipeline,
      ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      data-testid="pipeline-editor-mini-graph-upstream"
    />
    <pipeline-mini-graph :stages="pipelineStages" />
    <linked-pipelines-mini-list
      v-if="hasDownstreamPipelines"
      :triggered="downstreamPipelines"
      :pipeline-path="pipelinePath"
      data-testid="pipeline-editor-mini-graph-downstream"
    />
  </div>
</template>
