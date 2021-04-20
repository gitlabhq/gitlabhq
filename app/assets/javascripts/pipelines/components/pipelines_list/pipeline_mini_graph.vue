<script>
import PipelineStage from '~/pipelines/components/pipelines_list/pipeline_stage.vue';
/**
 * Renders the pipeline mini graph.
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
    stagesClass: {
      type: [Array, Object, String],
      required: false,
      default: '',
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    onPipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>
<template>
  <div data-testid="pipeline-mini-graph">
    <div
      v-for="stage in stages"
      :key="stage.name"
      :class="stagesClass"
      class="stage-container dropdown"
    >
      <pipeline-stage
        :stage="stage"
        :update-dropdown="updateDropdown"
        :is-merge-train="isMergeTrain"
        @pipelineActionRequestComplete="onPipelineActionRequestComplete"
      />
    </div>
  </div>
</template>
