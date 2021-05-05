<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

const badge = {
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
      required: true,
    },
  },
  computed: {
    variant() {
      return badge[this.type]?.variant;
    },
    text() {
      return badge[this.type]?.text;
    },
  },
};
</script>
<template>
  <gl-badge v-if="text" :variant="variant" v-bind="$attrs">
    {{ text }}
  </gl-badge>
</template>
