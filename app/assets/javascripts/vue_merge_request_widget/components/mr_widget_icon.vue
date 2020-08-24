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
  <div class="circle-icon-container gl-mr-3 align-self-start align-self-lg-center">
    <gl-icon :name="name" :size="24" />
  </div>
</template>
