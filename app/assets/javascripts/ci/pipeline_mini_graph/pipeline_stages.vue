<script>
import PipelineStage from './pipeline_stage.vue';
/**
 * Renders the pipeline stages portion of the pipeline mini graph.
 */
export default {
  name: 'PipelineStages',
  components: {
    PipelineStage,
  },
  props: {
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
    stages: {
      type: Array,
      required: true,
    },
  },
  emits: ['jobActionExecuted', 'miniGraphStageClick'],
};
</script>
<template>
  <div class="gl-inline gl-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.id"
      class="pipeline-mini-graph-stage-container dropdown gl-my-2 gl-mr-2 gl-inline-flex gl-align-middle"
    >
      <pipeline-stage
        :stage="stage"
        :is-merge-train="isMergeTrain"
        @jobActionExecuted="$emit('jobActionExecuted')"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
    </div>
  </div>
</template>
