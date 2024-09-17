<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  shapes: [
    { type: 'rect', width: '220', height: '10', x: '0', y: '20' },
    { type: 'rect', width: '60', height: '10', x: '305', y: '20' },
    { type: 'rect', width: '60', height: '10', x: '535', y: '20' },
    { type: 'rect', width: '100', height: '10', x: '760', y: '20' },
    { type: 'rect', width: '30', height: '30', x: '970', y: '10', ref: 'button-loader' },
  ],
  rowsToRender: {
    mobile: 5,
    desktop: 20,
  },
};
</script>

<template>
  <div>
    <div class="gl-flex-col sm:gl-hidden" data-testid="mobile-loader">
      <gl-skeleton-loader
        v-for="index in $options.rowsToRender.mobile"
        :key="index"
        :width="500"
        :height="170"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <rect width="500" height="10" x="0" y="15" rx="4" />
        <rect width="500" height="10" x="0" y="45" rx="4" />
        <rect width="500" height="10" x="0" y="75" rx="4" />
        <rect width="500" height="10" x="0" y="105" rx="4" />
        <rect width="500" height="10" x="0" y="135" rx="4" />
      </gl-skeleton-loader>
    </div>
    <div class="gl-hidden gl-flex-col sm:gl-flex" data-testid="desktop-loader">
      <gl-skeleton-loader
        v-for="index in $options.rowsToRender.desktop"
        :key="index"
        :width="1000"
        :height="54"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <component
          :is="r.type"
          v-for="(r, rIndex) in $options.shapes"
          :key="rIndex"
          rx="4"
          v-bind="r"
        />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
