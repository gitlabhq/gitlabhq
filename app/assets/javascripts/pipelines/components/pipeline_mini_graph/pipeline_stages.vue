<script>
import PipelineStage from './pipeline_stage.vue';
/**
 * Renders the pipeline stages portion of the pipeline mini graph.
 */
export default {
  components: {
    PipelineStage,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
    updateDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div data-testid="pipeline-stages" class="gl-display-inline gl-vertical-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.name"
      class="pipeline-mini-graph-stage-container dropdown gl-display-inline-block gl-mr-2 gl-my-2 gl-vertical-align-middle"
    >
      <pipeline-stage
        :stage="stage"
        :update-dropdown="updateDropdown"
        :is-merge-train="isMergeTrain"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
    </div>
  </div>
</template>
