<script>
import { GlTooltipDirective } from '@gitlab/ui';

import RunnerStatusBadge from '../runner_status_badge.vue';
import RunnerPausedBadge from '../runner_paused_badge.vue';

export default {
  components: {
    RunnerStatusBadge,
    RunnerPausedBadge,
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
    <slot :runner="runner" name="runner-job-status-badge"></slot>
  </div>
</template>
