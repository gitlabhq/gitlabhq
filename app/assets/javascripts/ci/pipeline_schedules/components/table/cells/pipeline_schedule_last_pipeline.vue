<script>
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';

export default {
  components: {
    CiBadge,
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
  <div>
    <ci-badge v-if="hasPipeline" :status="lastPipelineStatus" class="gl-vertical-align-middle" />
    <span v-else data-testid="pipeline-schedule-status-text">
      {{ s__('PipelineSchedules|None') }}
    </span>
  </div>
</template>
