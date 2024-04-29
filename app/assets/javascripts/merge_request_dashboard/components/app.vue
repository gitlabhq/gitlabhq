<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
};
</script>

<template>
  <div>
    <div class="page-title-holder">
      <h1 class="page-title gl-font-size-h-display">{{ __('Merge Requests') }}</h1>
    </div>
    <gl-loading-icon size="lg" />
  </div>
</template>
