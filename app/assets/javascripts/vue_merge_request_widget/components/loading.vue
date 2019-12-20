<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div class="prepend-top-default">
    <div class="mr-widget-heading p-3">
      <gl-skeleton-loader :width="577" :height="12">
        <rect width="86" height="12" rx="2" />
        <rect x="96" width="300" height="12" rx="2" />
      </gl-skeleton-loader>
    </div>
    <div class="mr-widget-heading mr-widget-workflow p-3">
      <gl-skeleton-loader :width="577" :height="72">
        <rect width="120" height="12" rx="2" />
        <rect y="20" width="300" height="12" rx="2" />
        <rect y="40" width="60" height="12" rx="2" />
        <rect y="40" x="68" width="100" height="12" rx="2" />
        <rect y="60" width="40" height="12" rx="2" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
