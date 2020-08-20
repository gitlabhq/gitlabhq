<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    desktopShapes() {
      return this.isGroup ? this.$options.shapes.groups : this.$options.shapes.projects;
    },
    desktopHeight() {
      return this.isGroup ? 38 : 54;
    },
    mobileHeight() {
      return this.isGroup ? 160 : 170;
    },
  },
  shapes: {
    groups: [
      { type: 'rect', width: '100', height: '10', x: '0', y: '15' },
      { type: 'rect', width: '100', height: '10', x: '195', y: '15' },
      { type: 'rect', width: '60', height: '10', x: '475', y: '15' },
      { type: 'rect', width: '60', height: '10', x: '675', y: '15' },
      { type: 'rect', width: '100', height: '10', x: '900', y: '15' },
    ],
    projects: [
      { type: 'rect', width: '220', height: '10', x: '0', y: '20' },
      { type: 'rect', width: '60', height: '10', x: '305', y: '20' },
      { type: 'rect', width: '60', height: '10', x: '535', y: '20' },
      { type: 'rect', width: '100', height: '10', x: '760', y: '20' },
      { type: 'rect', width: '30', height: '30', x: '970', y: '10', ref: 'button-loader' },
    ],
  },
  rowsToRender: {
    mobile: 5,
    desktop: 20,
  },
};
</script>

<template>
  <div>
    <div class="d-xs-flex flex-column d-md-none">
      <gl-skeleton-loader
        v-for="index in $options.rowsToRender.mobile"
        :key="index"
        :width="500"
        :height="mobileHeight"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <rect width="500" height="10" x="0" y="15" rx="4" />
        <rect width="500" height="10" x="0" y="45" rx="4" />
        <rect width="500" height="10" x="0" y="75" rx="4" />
        <rect width="500" height="10" x="0" y="105" rx="4" />
        <rect v-if="isGroup" width="500" height="10" x="0" y="135" rx="4" />
        <rect v-else width="30" height="30" x="470" y="135" rx="4" />
      </gl-skeleton-loader>
    </div>

    <div class="d-none d-md-flex flex-column">
      <gl-skeleton-loader
        v-for="index in $options.rowsToRender.desktop"
        :key="index"
        :width="1000"
        :height="desktopHeight"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <component
          :is="r.type"
          v-for="(r, rIndex) in desktopShapes"
          :key="rIndex"
          rx="4"
          v-bind="r"
        />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
