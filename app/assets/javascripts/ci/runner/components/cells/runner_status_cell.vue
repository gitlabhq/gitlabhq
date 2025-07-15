<script>
import { GlTooltipDirective } from '@gitlab/ui';

import RunnerStatusBadge from '../runner_status_badge.vue';
import RunnerPausedBadge from '../runner_paused_badge.vue';
import RunnerJobStatusBadge from '../runner_job_status_badge.vue';

export default {
  components: {
    RunnerStatusBadge,
    RunnerPausedBadge,
    RunnerJobStatusBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    paused() {
      return this.runner.paused;
    },
    contactedAt() {
      return this.runner.contactedAt;
    },
    status() {
      return this.runner.status;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-wrap gl-gap-2">
    <runner-status-badge :contacted-at="contactedAt" :status="status" />
    <runner-paused-badge v-if="paused" />
    <runner-job-status-badge :job-status="runner.jobExecutionStatus" />
  </div>
</template>
