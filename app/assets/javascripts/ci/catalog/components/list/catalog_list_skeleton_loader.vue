<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  data() {
    return {
      coordinates: {
        statsX: 0,
        releaseDateX: 0,
      },
      width: 0,
    };
  },
  mounted() {
    this.setSvgSize();
  },
  methods: {
    setSvgSize() {
      this.width = this.$el.offsetWidth;
      this.coordinates.releaseDateX = this.width - 200;
      this.coordinates.statsX = this.width - 90;
    },
  },
  skeletonLoadItems: new Array(5),
};
</script>
<template>
  <div class="gl-w-full">
    <gl-skeleton-loader
      v-for="(_, index) in $options.skeletonLoadItems"
      :key="index"
      :height="60"
      :width="width"
    >
      <!-- Catalog project avatar -->
      <rect x="0" y="0" width="48" height="48" rx="4" ry="4" />
      <!-- resource path -->
      <rect x="60" y="0" width="200" height="10" rx="2" ry="2" />
      <!-- resource name -->
      <rect x="60" y="14" width="400" height="16" rx="2" ry="2" />
      <!-- Project description -->
      <rect x="60" y="34" width="500" height="12" rx="2" ry="2" />

      <!-- Release date line -->
      <rect :x="coordinates.releaseDateX" y="30" width="200" height="12" rx="2" ry="2" />

      <!-- Favorites -->
      <rect :x="coordinates.statsX + 50" y="4" width="16" height="16" rx="2" ry="2" />
      <rect :x="coordinates.statsX + 70" y="7" width="18" height="10" rx="2" ry="2" />
    </gl-skeleton-loader>
  </div>
</template>
