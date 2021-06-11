<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

const BADGE_DATA = {
  [INSTANCE_TYPE]: {
    variant: 'success',
    text: s__('Runners|shared'),
  },
  [GROUP_TYPE]: {
    variant: 'success',
    text: s__('Runners|group'),
  },
  [PROJECT_TYPE]: {
    variant: 'info',
    text: s__('Runners|specific'),
  },
};

export default {
  components: {
    GlBadge,
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
  <gl-badge v-if="badge" :variant="badge.variant" v-bind="$attrs">
    {{ badge.text }}
  </gl-badge>
</template>
