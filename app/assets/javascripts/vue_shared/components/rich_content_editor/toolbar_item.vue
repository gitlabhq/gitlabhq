<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <button class="p-0 gl-display-flex toolbar-button">
    <gl-icon class="gl-mx-auto" :name="icon" />
  </button>
</template>
