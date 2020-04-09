<script>
import { GlNewButton } from '@gitlab/ui';

export default {
  components: {
    GlNewButton,
  },
  props: {
    saveable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div class="d-flex bg-light border-top justify-content-between align-items-center py-3 px-4">
    <gl-new-button variant="success" :disabled="!saveable">
      {{ __('Submit Changes') }}
    </gl-new-button>
  </div>
</template>
