<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: { GlIcon },
  props: {
    name: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="circle-icon-container align-self-start gl-mr-3 gl-mt-2">
    <gl-icon :name="name" :size="24" variant="subtle" />
  </div>
</template>
