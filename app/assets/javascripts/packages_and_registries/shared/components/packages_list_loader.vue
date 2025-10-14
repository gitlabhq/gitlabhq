<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  shapes: [
    { type: 'rect', width: '320', height: '12', x: '0', y: '12' },
    { type: 'rect', width: '240', height: '8', x: '0', y: '32' },
    { type: 'rect', width: '160', height: '12', x: '790', y: '12' },
    { type: 'rect', width: '140', height: '8', x: '790', y: '32' },
    { type: 'rect', width: '8', height: '20', x: '980', y: '16', ref: 'button-loader' },
  ],
  rowsToRender: {
    mobile: 5,
    desktop: 10,
  },
};
</script>

<template>
  <div>
    <div class="gl-flex-col @sm/panel:gl-hidden" data-testid="mobile-loader">
      <div v-for="index in $options.rowsToRender.mobile" :key="index" class="gl-border-b">
        <gl-skeleton-loader
          :key="index"
          :width="500"
          :height="95"
          preserve-aspect-ratio="xMinYMax meet"
        >
          <rect width="500" height="10" x="0" y="15" rx="4" />
          <rect width="200" height="10" x="0" y="35" rx="4" />
          <rect width="200" height="10" x="0" y="55" rx="4" />
          <rect width="300" height="10" x="0" y="75" rx="4" />>
        </gl-skeleton-loader>
      </div>
    </div>
    <div class="gl-mb-5 gl-hidden gl-flex-col @sm/panel:gl-flex" data-testid="desktop-loader">
      <div v-for="index in $options.rowsToRender.desktop" :key="index" class="gl-border-b">
        <gl-skeleton-loader
          :key="index"
          :width="1000"
          :height="48"
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
  </div>
</template>
