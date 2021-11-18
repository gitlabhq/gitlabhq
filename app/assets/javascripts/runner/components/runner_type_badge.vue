<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_INSTANCE_RUNNER_DESCRIPTION,
  I18N_GROUP_RUNNER_DESCRIPTION,
  I18N_PROJECT_RUNNER_DESCRIPTION,
} from '../constants';

const BADGE_DATA = {
  [INSTANCE_TYPE]: {
    text: s__('Runners|shared'),
    tooltip: I18N_INSTANCE_RUNNER_DESCRIPTION,
  },
  [GROUP_TYPE]: {
    text: s__('Runners|group'),
    tooltip: I18N_GROUP_RUNNER_DESCRIPTION,
  },
  [PROJECT_TYPE]: {
    text: s__('Runners|specific'),
    tooltip: I18N_PROJECT_RUNNER_DESCRIPTION,
  },
};

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: null,
      validator(type) {
        return Boolean(BADGE_DATA[type]);
      },
    },
  },
  computed: {
    badge() {
      return BADGE_DATA[this.type];
    },
  },
};
</script>
<template>
  <gl-badge v-if="badge" v-gl-tooltip="badge.tooltip" variant="info" v-bind="$attrs">
    {{ badge.text }}
  </gl-badge>
</template>
