<script>
import { GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
  },
  props: {
    tagList: {
      type: Array,
      required: false,
      default: () => [],
    },
    size: {
      type: String,
      required: false,
      default: 'md',
    },
    variant: {
      type: String,
      required: false,
      default: 'info',
    },
  },
};
</script>
<template>
  <div>
    <gl-badge v-for="tag in tagList" :key="tag" :size="size" :variant="variant">
      {{ tag }}
    </gl-badge>
  </div>
</template>
