<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';

import { I18N_RESUME, I18N_PAUSE } from '../constants';
import RunnerPauseAction from './runner_pause_action.vue';

export default {
  name: 'RunnerPauseDisclosureDropdownItem',
  components: {
    GlDisclosureDropdownItem,
    RunnerPauseAction,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  emits: ['toggledPaused'],
  computed: {
    item() {
      return { text: this.runner.paused ? I18N_RESUME : I18N_PAUSE };
    },
  },
};
</script>

<template>
  <runner-pause-action :runner="runner" @done="$emit('toggledPaused')">
    <template #default="{ onClick }">
      <gl-disclosure-dropdown-item :item="item" @action="onClick" />
    </template>
  </runner-pause-action>
</template>
