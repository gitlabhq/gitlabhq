<script>
import PipelineStage from './pipeline_stage.vue';
import LegacyPipelineStage from './legacy_pipeline_stage.vue';
/**
 * Renders the pipeline stages portion of the pipeline mini graph.
 */
export default {
  components: {
    LegacyPipelineStage,
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
    pipelineEtag: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div class="gl-display-inline gl-vertical-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.name"
      class="pipeline-mini-graph-stage-container dropdown gl-display-inline-flex gl-mr-2 gl-my-2 gl-vertical-align-middle"
    >
      <pipeline-stage
        v-if="isGraphql"
        :stage-id="stage.id"
        :is-merge-train="isMergeTrain"
        :pipeline-etag="pipelineEtag"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
      <legacy-pipeline-stage
        v-else
        :stage="stage"
        :update-dropdown="updateDropdown"
        :is-merge-train="isMergeTrain"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
    </div>
  </div>
</template>
