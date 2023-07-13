<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';

import { I18N_RESUME, I18N_PAUSE, I18N_PAUSE_TOOLTIP, I18N_RESUME_TOOLTIP } from '../constants';
import RunnerPauseAction from './runner_pause_action.vue';

export default {
  name: 'RunnerPauseButton',
  components: {
    GlButton,
    RunnerPauseAction,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggledPaused'],
  computed: {
    isPaused() {
      return this.runner.paused;
    },
    tooltip() {
      return this.isPaused ? I18N_RESUME_TOOLTIP : I18N_PAUSE_TOOLTIP;
    },
    icon() {
      return this.isPaused ? 'play' : 'pause';
    },
    label() {
      return this.isPaused ? I18N_RESUME : I18N_PAUSE;
    },
    ariaLabel() {
      if (this.compact) {
        return this.label;
      }
      return null;
    },
    buttonContent() {
      if (this.compact) {
        return null;
      }
      return this.label;
    },
  },
};
</script>

<template>
  <runner-pause-action :runner="runner" @done="$emit('toggledPaused')">
    <template #default="{ loading, onClick }">
      <gl-button
        v-gl-tooltip="loading ? '' : tooltip"
        :icon="icon"
        :aria-label="ariaLabel"
        :loading="loading"
        @click="onClick"
      >
        <template v-if="buttonContent">{{ buttonContent }}</template>
      </gl-button>
    </template>
  </runner-pause-action>
</template>
