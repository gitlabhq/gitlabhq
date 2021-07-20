<script>
import { GlBadge } from '@gitlab/ui';
import { RUNNER_TAG_BADGE_VARIANT } from '../constants';

export default {
  components: {
    GlBadge,
  },
  props: {
    tag: {
      type: String,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: 'md',
    },
  },
  RUNNER_TAG_BADGE_VARIANT,
};
</script>
<template>
  <gl-badge :size="size" :variant="$options.RUNNER_TAG_BADGE_VARIANT">
    {{ tag }}
  </gl-badge>
</template>
