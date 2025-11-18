<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'ObservabilityLoading',
  components: {
    GlLoadingIcon,
  },
};
</script>

<template>
  <div
    class="gl-flex gl-h-[60vh] gl-min-h-[400px] gl-w-full gl-items-center gl-justify-center gl-bg-default"
  >
    <gl-loading-icon size="md" :label="s__('Observability|Loading...')" />
  </div>
</template>
