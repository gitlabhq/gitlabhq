<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'ReconciliationSkeletonLoader',
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <gl-skeleton-loader :width="600" :height="310">
    <circle cx="300" cy="50" r="50" />

    <rect x="150" y="116" width="300" height="20" rx="4" />

    <rect x="40" y="148" width="520" height="12" rx="4" />
    <rect x="100" y="168" width="400" height="12" rx="4" />

    <rect x="200" y="192" width="200" height="12" rx="4" />

    <rect y="224" width="185" height="80" rx="4" />
    <rect x="12" y="244" width="32" height="32" rx="4" />
    <rect x="52" y="250" width="100" height="12" rx="4" />

    <rect x="205" y="224" width="185" height="80" rx="4" />
    <rect x="217" y="244" width="32" height="32" rx="4" />
    <rect x="257" y="250" width="100" height="12" rx="4" />

    <rect x="410" y="224" width="185" height="80" rx="4" />
    <rect x="422" y="244" width="32" height="32" rx="4" />
    <rect x="462" y="250" width="100" height="12" rx="4" />
  </gl-skeleton-loader>
</template>
