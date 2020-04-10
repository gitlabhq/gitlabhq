<script>
import { GlNewButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlNewButton,
    GlLoadingIcon,
  },
  props: {
    saveable: {
      type: Boolean,
      required: false,
      default: false,
    },
    savingChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div class="d-flex bg-light border-top justify-content-between align-items-center py-3 px-4">
    <gl-loading-icon :class="{ invisible: !savingChanges }" size="md" />
    <gl-new-button
      variant="success"
      :disabled="!saveable || savingChanges"
      @click="$emit('submit')"
    >
      {{ __('Submit Changes') }}
    </gl-new-button>
  </div>
</template>
