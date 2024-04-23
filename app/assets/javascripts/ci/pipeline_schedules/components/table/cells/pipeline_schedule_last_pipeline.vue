<script>
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

export default {
  components: {
    CiIcon,
  },
  props: {
    schedule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasPipeline() {
      return this.schedule.lastPipeline;
    },
    lastPipelineStatus() {
      return this.schedule?.lastPipeline?.detailedStatus;
    },
  },
};
</script>

<template>
  <div data-testid="last-pipeline-status">
    <ci-icon
      v-if="hasPipeline"
      :status="lastPipelineStatus"
      show-status-text
      class="gl-align-middle"
    />
    <span v-else data-testid="pipeline-schedule-status-text">
      {{ s__('PipelineSchedules|None') }}
    </span>
  </div>
</template>
