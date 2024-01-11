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
  <div class="gl-display-flex gl-flex-wrap gl-gap-2">
    <runner-status-badge
      :contacted-at="contactedAt"
      :status="status"
      class="gl-max-w-full gl-text-truncate"
    />
    <runner-paused-badge v-if="paused" class="gl-max-w-full gl-text-truncate" />
    <slot :runner="runner" name="runner-job-status-badge"></slot>
  </div>
</template>
