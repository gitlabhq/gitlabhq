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
      return !this.runner.active;
    },
  },
};
</script>

<template>
  <div>
    <runner-status-badge :runner="runner" size="sm" />
    <runner-paused-badge v-if="paused" size="sm" />
  </div>
</template>
