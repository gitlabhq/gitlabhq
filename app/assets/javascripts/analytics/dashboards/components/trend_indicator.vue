<script>
import { GlIcon } from '@gitlab/ui';
import { UNITS } from '../../shared/constants';
import { formatMetric } from '../utils';
import { TREND_STYLES, TREND_STYLE_ASC, TREND_STYLE_DESC } from '../constants';

export default {
  name: 'TrendIndicator',
  components: {
    GlIcon,
  },
  props: {
    change: {
      type: Number,
      required: true,
    },
    trendStyle: {
      type: String,
      required: false,
      default: TREND_STYLE_ASC,
      validator: (style) => TREND_STYLES.includes(style),
    },
  },
  computed: {
    trendingUp() {
      return this.change > 0;
    },
    textColor() {
      switch (this.trendStyle) {
        case TREND_STYLE_ASC:
          return this.trendingUp ? 'gl-text-success' : 'gl-text-danger';
        case TREND_STYLE_DESC:
          return this.trendingUp ? 'gl-text-danger' : 'gl-text-success';
        default:
          return 'gl-text-color-default';
      }
    },
    iconName() {
      return this.trendingUp ? 'trend-up' : 'trend-down';
    },
    formattedChange() {
      return formatMetric(Math.abs(this.change * 100), UNITS.PERCENT);
    },
  },
};
</script>
<template>
  <span :class="textColor">
    <gl-icon :size="12" :name="iconName" />
    {{ formattedChange }}
  </span>
</template>
