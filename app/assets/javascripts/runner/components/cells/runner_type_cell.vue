<script>
import { GlBadge } from '@gitlab/ui';
import RunnerTypeBadge from '../runner_type_badge.vue';

export default {
  components: {
    GlBadge,
    RunnerTypeBadge,
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
};
</script>

<template>
  <div>
    <runner-type-badge :type="runnerType" size="sm" />

    <gl-badge v-if="locked" variant="warning" size="sm">
      {{ s__('Runners|locked') }}
    </gl-badge>

    <gl-badge v-if="paused" variant="danger" size="sm">
      {{ s__('Runners|paused') }}
    </gl-badge>
  </div>
</template>
