<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
};
</script>

<template>
  <div class="dropdown-title gl-display-flex gl-justify-content-center">
    <span class="gl-ml-auto">{{ __('Assign labels') }}</span>
    <button
      :aria-label="__('Close')"
      type="button"
      class="dropdown-title-button dropdown-menu-close gl-ml-auto"
    >
      <gl-icon name="close" class="dropdown-menu-close-icon" />
    </button>
  </div>
</template>
