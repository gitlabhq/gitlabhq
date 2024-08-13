<script>
import { GlIcon } from '@gitlab/ui';
import LegacyLinkedPipelinesMiniList from './legacy_linked_pipelines_mini_list.vue';
import LegacyPipelineStages from './legacy_pipeline_stages.vue';
/**
 * Renders the REST instance of the pipeline mini graph.
 */
export default {
  components: {
    GlIcon,
    LegacyLinkedPipelinesMiniList,
    LegacyPipelineStages,
  },
  arrowStyles: ['arrow-icon gl-display-inline-block gl-mx-1 gl-text-gray-500 !gl-align-middle'],
  props: {
    downstreamPipelines: {
      type: Array,
      required: false,
      default: () => [],
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
    <legacy-linked-pipelines-mini-list
      v-if="upstreamPipeline"
      :triggered-by="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
        upstreamPipeline,
      ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      data-testid="pipeline-mini-graph-upstream"
    />
    <gl-icon
      v-if="upstreamPipeline"
      :class="$options.arrowStyles"
      name="arrow-right"
      data-testid="upstream-arrow-icon"
    />
    <legacy-pipeline-stages
      :is-merge-train="isMergeTrain"
      :stages="stages"
      :update-dropdown="updateDropdown"
      @miniGraphStageClick="$emit('miniGraphStageClick')"
    />
    <gl-icon
      v-if="hasDownstreamPipelines"
      :class="$options.arrowStyles"
      name="arrow-right"
      data-testid="downstream-arrow-icon"
    />
    <legacy-linked-pipelines-mini-list
      v-if="hasDownstreamPipelines"
      :triggered="downstreamPipelines"
      :pipeline-path="pipelinePath"
      data-testid="pipeline-mini-graph-downstream"
    />
  </div>
</template>
