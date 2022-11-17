<script>
import { GlTooltipDirective } from '@gitlab/ui';

import RunnerStatusBadge from '../runner_status_badge.vue';
import RunnerPausedBadge from '../runner_paused_badge.vue';

export default {
  components: {
    RunnerStatusBadge,
    RunnerUpgradeStatusBadge: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_badge.vue'),
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
    <runner-status-badge
      :runner="runner"
      class="gl-display-inline-block gl-max-w-full gl-text-truncate"
    />
    <runner-upgrade-status-badge
      :runner="runner"
      class="gl-display-inline-block gl-max-w-full gl-text-truncate"
    />
    <runner-paused-badge
      v-if="paused"
      class="gl-display-inline-block gl-max-w-full gl-text-truncate"
    />
  </div>
</template>
