<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
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

const ICON_DATA = {
  [INSTANCE_TYPE]: {
    name: 'users',
    tooltip: `${I18N_INSTANCE_TYPE}: ${I18N_INSTANCE_RUNNER_DESCRIPTION}`,
  },
  [GROUP_TYPE]: {
    name: 'group',
    tooltip: `${I18N_GROUP_TYPE}: ${I18N_GROUP_RUNNER_DESCRIPTION}`,
  },
  [PROJECT_TYPE]: {
    name: 'project',
    tooltip: `${I18N_PROJECT_TYPE}: ${I18N_PROJECT_RUNNER_DESCRIPTION}`,
  },
};

export default {
  components: {
    GlIcon,
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
        return Boolean(ICON_DATA[type]);
      },
    },
  },
  computed: {
    icon() {
      return ICON_DATA[this.type];
    },
  },
};
</script>
<template>
  <gl-icon
    v-if="icon"
    v-gl-tooltip="icon.tooltip"
    :aria-label="icon.tooltip"
    :name="icon.name"
    v-bind="$attrs"
  />
</template>
