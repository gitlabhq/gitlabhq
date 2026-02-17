<script>
import PipelineStageDropdown from './pipeline_stage_dropdown.vue';
/**
 * Renders the pipeline stages portion of the pipeline mini graph.
 */
export default {
  name: 'PipelineStages',
  components: {
    PipelineStageDropdown,
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
  emits: ['job-action-executed', 'mini-graph-stage-click'],
};
</script>
<template>
  <div class="gl-contents gl-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.id"
      class="pipeline-mini-graph-stage-container dropdown gl-my-1 gl-mr-2 gl-inline-flex gl-align-middle"
    >
      <pipeline-stage-dropdown
        :stage="stage"
        :is-merge-train="isMergeTrain"
        @job-action-executed="$emit('job-action-executed')"
        @mini-graph-stage-click="$emit('mini-graph-stage-click')"
      />
    </div>
  </div>
</template>
