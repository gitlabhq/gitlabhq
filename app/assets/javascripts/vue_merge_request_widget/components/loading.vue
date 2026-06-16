<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'VueMergeRequestWidgetLoading',
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <div class="mr-section-container gl-p-4">
      <gl-skeleton-loader :width="1154" :height="12">
        <rect width="172" height="12" rx="2" />
        <rect x="192" width="600" height="12" rx="2" />
      </gl-skeleton-loader>
    </div>
    <div class="mr-section-container gl-p-4">
      <gl-skeleton-loader :width="1154" :height="72">
        <rect width="240" height="12" rx="2" />
        <rect y="20" width="600" height="12" rx="2" />
        <rect y="40" width="120" height="12" rx="2" />
        <rect y="40" x="136" width="200" height="12" rx="2" />
        <rect y="60" width="80" height="12" rx="2" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
