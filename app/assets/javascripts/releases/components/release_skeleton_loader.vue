<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'ReleaseSkeletonLoader',
  components: { GlSkeletonLoader },
};
</script>
<template>
  <gl-skeleton-loader :width="1248" :height="420">
    <!-- Outside border -->
    <path
      d="M 4.5 0 C 2.0156486 0 0 2.0156486 0 4.5 L 0 415.5 C 0 417.98435 2.0156486 420 4.5 420 L 1243.5 420 C 1245.9844 420 1248 417.98435 1248 415.5 L 1248 4.5 C 1248 2.0156486 1245.9844 0 1243.5 0 L 4.5 0 z M 4.5 1 L 1243.5 1 C 1245.4476 1 1247 2.5523514 1247 4.5 L 1247 415.5 C 1247 417.44765 1245.4476 419 1243.5 419 L 4.5 419 C 2.5523514 419 1 417.44765 1 415.5 L 1 4.5 C 1 2.5523514 2.5523514 1 4.5 1 z "
    />

    <!-- Header bottom border -->
    <rect x="0" y="63.5" width="1248" height="1" />

    <!-- Release title -->
    <rect x="16" y="20" width="293" height="24" />

    <!-- Edit (pencil) button -->
    <rect x="1207" y="16" rx="4" width="32" height="32" />

    <!-- Asset link 1 -->
    <rect x="40" y="121" rx="4" width="16" height="16" />
    <rect x="60" y="125" width="116" height="8" />

    <!-- Asset link 2 -->
    <rect x="40" y="145" rx="4" width="16" height="16" />
    <rect x="60" y="149" width="132" height="8" />

    <!-- Asset link 3 -->
    <rect x="40" y="169" rx="4" width="16" height="16" />
    <rect x="60" y="173" width="140" height="8" />

    <!-- Asset link 4 -->
    <rect x="40" y="193" rx="4" width="16" height="16" />
    <rect x="60" y="197" width="112" height="8" />

    <!-- Release notes -->
    <rect x="16" y="228" width="480" height="8" />
    <rect x="16" y="252" width="560" height="8" />
    <rect x="16" y="276" width="480" height="8" />
    <rect x="16" y="300" width="560" height="8" />
    <rect x="16" y="324" width="320" height="8" />

    <!-- Footer top border -->
    <rect x="0" y="373" width="1248" height="1" />
  </gl-skeleton-loader>
</template>
