<script>
import { GlSkeletonLoader } from '@gitlab/ui';

import {
  DEFAULT_RX,
  DEFAULT_BAR_WIDTH,
  DEFAULT_LABEL_WIDTH,
  DEFAULT_LABEL_HEIGHT,
  BAR_HEIGHTS,
  GRID_YS,
} from './constants';

export default {
  components: {
    GlSkeletonLoader,
  },
  props: {
    barWidth: {
      type: Number,
      default: DEFAULT_BAR_WIDTH,
      required: false,
    },
    labelWidth: {
      type: Number,
      default: DEFAULT_LABEL_WIDTH,
      required: false,
    },
    labelHeight: {
      type: Number,
      default: DEFAULT_LABEL_HEIGHT,
      required: false,
    },
    rx: {
      type: Number,
      default: DEFAULT_RX,
      required: false,
    },
    // skeleton-loader will generate a unique key if not defined
    uniqueKey: {
      type: String,
      default: undefined,
      required: false,
    },
  },
  computed: {
    labelCentering() {
      return (this.barWidth - this.labelWidth) / 2;
    },
  },
  methods: {
    getBarXPosition(index) {
      const numberOfBars = this.$options.BAR_HEIGHTS.length;
      const numberOfSpaces = numberOfBars + 1;
      const spaceBetweenBars = (100 - numberOfSpaces * this.barWidth) / numberOfBars;

      return (0.5 + index) * (this.barWidth + spaceBetweenBars);
    },
  },
  BAR_HEIGHTS,
  GRID_YS,
};
</script>
<template>
  <div class="gl-px-8">
    <gl-skeleton-loader :unique-key="uniqueKey" class="gl-p-8">
      <rect
        v-for="(y, index) in $options.GRID_YS"
        :key="`grid-${index}`"
        data-testid="skeleton-chart-grid"
        x="0"
        :y="`${y}%`"
        width="100%"
        height="1px"
      />
      <rect
        v-for="(height, index) in $options.BAR_HEIGHTS"
        :key="`bar-${index}`"
        data-testid="skeleton-chart-bar"
        :x="`${getBarXPosition(index)}%`"
        :y="`${90 - height}%`"
        :width="`${barWidth}%`"
        :height="`${height}%`"
        :rx="`${rx}%`"
      />
      <rect
        v-for="(height, index) in $options.BAR_HEIGHTS"
        :key="`label-${index}`"
        data-testid="skeleton-chart-label"
        :x="`${labelCentering + getBarXPosition(index)}%`"
        :y="`${100 - labelHeight}%`"
        :width="`${labelWidth}%`"
        :height="`${labelHeight}%`"
        :rx="`${rx}%`"
      />
    </gl-skeleton-loader>
  </div>
</template>
