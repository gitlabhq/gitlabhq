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
    pipelineEtag: {
      type: String,
      required: false,
      default: '',
    },
    stages: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-inline gl-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.id"
      class="pipeline-mini-graph-stage-container dropdown gl-inline-flex gl-mr-2 gl-my-2 gl-align-middle"
    >
      <pipeline-stage
        :stage="stage"
        :is-merge-train="isMergeTrain"
        :pipeline-etag="pipelineEtag"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
    </div>
  </div>
</template>
