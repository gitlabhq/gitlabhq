<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'InputsTableSkeletonLoader',
  components: {
    GlSkeletonLoader,
  },
  methods: {
    getSkeletonRectProps(columnIndex, rowIndex) {
      return {
        x: `${columnIndex * 25.5}%`,
        y: rowIndex * 10,
        width: '23%',
        height: 6,
        rx: 2,
        ry: 2,
      };
    },
  },
};
</script>

<template>
  <gl-skeleton-loader :height="16">
    <template v-for="rowIndex in 2">
      <rect
        v-for="colIndex in 4"
        :key="`${rowIndex - 1}-${colIndex - 1}`"
        v-bind="getSkeletonRectProps(colIndex - 1, rowIndex - 1)"
      />
    </template>
  </gl-skeleton-loader>
</template>
