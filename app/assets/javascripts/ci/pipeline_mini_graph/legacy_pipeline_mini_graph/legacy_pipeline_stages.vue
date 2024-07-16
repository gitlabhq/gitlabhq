<script>
import LegacyPipelineStage from './legacy_pipeline_stage.vue';
/**
 * Renders the pipeline stages portion of the legacy pipeline mini graph.
 */
export default {
  components: {
    LegacyPipelineStage,
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
  <div class="gl-display-inline gl-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.name"
      class="pipeline-mini-graph-stage-container dropdown gl-inline-flex gl-mr-2 gl-my-2 gl-align-middle"
    >
      <legacy-pipeline-stage
        :stage="stage"
        :update-dropdown="updateDropdown"
        :is-merge-train="isMergeTrain"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
    </div>
  </div>
</template>
