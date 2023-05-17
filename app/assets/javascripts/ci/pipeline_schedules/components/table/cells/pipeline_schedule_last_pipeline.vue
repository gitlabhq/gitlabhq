<script>
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';

export default {
  components: {
    CiBadgeLink,
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
    <ci-badge-link
      v-if="hasPipeline"
      :status="lastPipelineStatus"
      class="gl-vertical-align-middle"
    />
    <span v-else data-testid="pipeline-schedule-status-text">
      {{ s__('PipelineSchedules|None') }}
    </span>
  </div>
</template>
