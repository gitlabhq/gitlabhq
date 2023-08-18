<script>
import { GlIcon } from '@gitlab/ui';
import PipelineStages from './pipeline_stages.vue';
import LinkedPipelinesMiniList from './linked_pipelines_mini_list.vue';
/**
 * Renders the pipeline mini graph.
 * TODO: After all apps have updated to GraphQL data and use the `pipeline_mini_graph.vue` file as an entry,
 * we should rename this file to `pipeline_mini_graph_wrapper.vue`
 */
export default {
  components: {
    GlIcon,
    LinkedPipelinesMiniList,
    PipelineStages,
  },
  arrowStyles: [
    'arrow-icon gl-display-inline-block gl-mx-1 gl-text-gray-500 gl-vertical-align-middle!',
  ],
  props: {
    downstreamPipelines: {
      type: Array,
      required: false,
      default: () => [],
    },
    isGraphql: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelinePath: {
      type: String,
      required: false,
      default: '',
    },
    stages: {
      type: Array,
      required: true,
      default: () => [],
    },
    updateDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    upstreamPipeline: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  computed: {
    hasDownstreamPipelines() {
      return Boolean(this.downstreamPipelines.length);
    },
  },
};
</script>
<template>
  <div data-testid="pipeline-mini-graph">
    <linked-pipelines-mini-list
      v-if="upstreamPipeline"
      :triggered-by="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
        upstreamPipeline,
      ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      data-testid="pipeline-mini-graph-upstream"
    />
    <gl-icon
      v-if="upstreamPipeline"
      :class="$options.arrowStyles"
      name="long-arrow"
      data-testid="upstream-arrow-icon"
    />
    <pipeline-stages
      :is-graphql="isGraphql"
      :is-merge-train="isMergeTrain"
      :stages="stages"
      :update-dropdown="updateDropdown"
      @miniGraphStageClick="$emit('miniGraphStageClick')"
    />
    <gl-icon
      v-if="hasDownstreamPipelines"
      :class="$options.arrowStyles"
      name="long-arrow"
      data-testid="downstream-arrow-icon"
    />
    <linked-pipelines-mini-list
      v-if="hasDownstreamPipelines"
      :triggered="downstreamPipelines"
      :pipeline-path="pipelinePath"
      data-testid="pipeline-mini-graph-downstream"
    />
  </div>
</template>
