<script>
import { GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
  },
  props: {
    duration: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <gl-badge>
    {{ duration }}
  </gl-badge>
</template>
