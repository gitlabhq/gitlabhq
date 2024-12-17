<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div class="gl-pt-6">
    <gl-skeleton-loader :width="1248" :height="200">
      <rect x="8" y="0" width="24" height="24" />
      <rect x="46" y="5" width="247" height="15" />
      <rect x="0" y="49" width="1248" height="1" />

      <rect x="8" y="64" width="24" height="24" />
      <rect x="46" y="69" width="247" height="15" />
      <rect x="0" y="113" width="1248" height="1" />
      <rect x="1168" y="64" width="80" height="32" />

      <rect x="8" y="128" width="24" height="24" />
      <rect x="46" y="133" width="247" height="15" />
      <rect x="0" y="177" width="1248" height="1" />
      <rect x="1168" y="128" width="80" height="32" />
    </gl-skeleton-loader>
  </div>
</template>
