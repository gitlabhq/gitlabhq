<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
};
</script>
<template>
  <div
    data-testid="content-editor-loading-indicator"
    class="gl-w-full gl-display-flex gl-justify-content-center gl-align-items-center gl-absolute gl-top-0 gl-bottom-0"
  >
    <div class="gl-bg-white gl-absolute gl-w-full gl-h-full gl-opacity-3"></div>
    <gl-loading-icon size="lg" />
  </div>
</template>
