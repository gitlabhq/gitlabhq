<script>
import { GlTooltipDirective } from '@gitlab/ui';
import RunnerTypeBadge from '../runner_type_badge.vue';
import RunnerStateLockedBadge from '../runner_state_locked_badge.vue';
import RunnerStatePausedBadge from '../runner_state_paused_badge.vue';
import { I18N_LOCKED_RUNNER_DESCRIPTION, I18N_PAUSED_RUNNER_DESCRIPTION } from '../../constants';

export default {
  components: {
    RunnerTypeBadge,
    RunnerStateLockedBadge,
    RunnerStatePausedBadge,
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
    runnerType() {
      return this.runner.runnerType;
    },
    locked() {
      return this.runner.locked;
    },
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
    <runner-type-badge :type="runnerType" size="sm" />
    <runner-state-locked-badge v-if="locked" size="sm" />
    <runner-state-paused-badge v-if="paused" size="sm" />
  </div>
</template>
