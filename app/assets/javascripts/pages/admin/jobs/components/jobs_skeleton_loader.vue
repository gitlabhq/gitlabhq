<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <gl-skeleton-loader :width="1248" :height="73">
    <circle cx="748.031" cy="37.7193" r="15.0307" />
    <circle cx="787.241" cy="37.7193" r="15.0307" />
    <circle cx="827.759" cy="37.7193" r="15.0307" />
    <circle cx="866.969" cy="37.7193" r="15.0307" />
    <circle cx="380" cy="37" r="18" />
    <rect x="432" y="19" width="126.587" height="15" />
    <rect x="432" y="41" width="247" height="15" />
    <rect x="158" y="19" width="86.1" height="15" />
    <rect x="158" y="41" width="168" height="15" />
    <rect x="22" y="19" width="96" height="36" />
    <rect x="924" y="30" width="96" height="15" />
    <rect x="1057" y="20" width="166" height="35" />
  </gl-skeleton-loader>
</template>
