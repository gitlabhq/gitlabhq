<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'TabContentLoadingIndicator',
  components: { GlLoadingIcon },
};
</script>

<template>
  <div class="gl-my-5 gl-flex gl-w-full gl-items-center gl-justify-center gl-gap-3 gl-text-lg">
    {{ s__('UsageQuotas|Loading Usage Quotas tab content') }}
    <gl-loading-icon size="md" />
  </div>
</template>
