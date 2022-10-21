<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_INSTANCE_TYPE,
  I18N_INSTANCE_RUNNER_DESCRIPTION,
  I18N_GROUP_TYPE,
  I18N_GROUP_RUNNER_DESCRIPTION,
  I18N_PROJECT_TYPE,
  I18N_PROJECT_RUNNER_DESCRIPTION,
} from '../constants';

const BADGE_DATA = {
  [INSTANCE_TYPE]: {
    icon: 'users',
    text: I18N_INSTANCE_TYPE,
    tooltip: I18N_INSTANCE_RUNNER_DESCRIPTION,
  },
  [GROUP_TYPE]: {
    icon: 'group',
    text: I18N_GROUP_TYPE,
    tooltip: I18N_GROUP_RUNNER_DESCRIPTION,
  },
  [PROJECT_TYPE]: {
    icon: 'project',
    text: I18N_PROJECT_TYPE,
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
  <gl-badge
    v-if="badge"
    v-gl-tooltip="badge.tooltip"
    variant="muted"
    :icon="badge.icon"
    v-bind="$attrs"
  >
    {{ badge.text }}
  </gl-badge>
</template>
