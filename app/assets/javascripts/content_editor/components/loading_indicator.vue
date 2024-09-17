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
    class="gl-absolute gl-bottom-0 gl-top-0 gl-flex gl-w-full gl-items-center gl-justify-center"
  >
    <div class="gl-absolute gl-h-full gl-w-full gl-bg-white gl-opacity-3"></div>
    <gl-loading-icon size="lg" />
  </div>
</template>
