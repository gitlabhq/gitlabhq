<script>
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    TimeAgoTooltip,
  },
  props: {
    schedule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showTimeAgo() {
      return this.schedule.active && this.schedule.nextRunAt;
    },
    realNextRunTime() {
      return this.schedule.realNextRun;
    },
  },
};
</script>

<template>
  <div data-testid="next-run-cell">
    <time-ago-tooltip v-if="showTimeAgo" :time="realNextRunTime" />
    <span v-else data-testid="pipeline-schedule-inactive">
      {{ s__('PipelineSchedules|Inactive') }}
    </span>
  </div>
</template>
