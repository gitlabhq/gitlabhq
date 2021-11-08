<script>
import { GlTooltipDirective } from '@gitlab/ui';

import RunnerContactedStateBadge from '../runner_contacted_state_badge.vue';
import RunnerPausedBadge from '../runner_paused_badge.vue';

import { I18N_LOCKED_RUNNER_DESCRIPTION, I18N_PAUSED_RUNNER_DESCRIPTION } from '../../constants';

export default {
  components: {
    RunnerContactedStateBadge,
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
  i18n: {
    I18N_LOCKED_RUNNER_DESCRIPTION,
    I18N_PAUSED_RUNNER_DESCRIPTION,
  },
};
</script>

<template>
  <div>
    <runner-contacted-state-badge :runner="runner" size="sm" />
    <runner-paused-badge v-if="paused" size="sm" />
  </div>
</template>
