<script>
import { GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/src/charts';
import {
  GL_COLOR_DATA_GREEN_400,
  GL_COLOR_DATA_BLUE_600,
} from '@gitlab/ui/src/tokens/build/js/tokens';
import { TREND_STYLES, TREND_STYLE_ASC, TREND_STYLE_DESC } from '../../../../dashboards/constants';

export default {
  name: 'TrendLine',
  components: {
    GlSkeletonLoader,
    GlSparklineChart,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    data: {
      type: Array,
      required: true,
    },
    tooltipLabel: {
      type: String,
      required: false,
      default: '',
    },
    trendStyle: {
      type: String,
      required: false,
      default: TREND_STYLE_ASC,
      validator: (style) => TREND_STYLES.includes(style),
    },
  },
  computed: {
    gradient() {
      switch (this.trendStyle) {
        case TREND_STYLE_ASC:
          return [GL_COLOR_DATA_GREEN_400, GL_COLOR_DATA_BLUE_600];
        case TREND_STYLE_DESC:
          return [GL_COLOR_DATA_BLUE_600, GL_COLOR_DATA_GREEN_400];
        default:
          return [];
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-sparkline-chart
      v-if="data.length"
      :height="30"
      :tooltip-label="tooltipLabel"
      :show-last-y-value="false"
      :data="data"
      :smooth="0.2"
      :gradient="gradient"
      connect-nulls
      data-testid="metric-chart"
    />
    <div v-else class="gl-py-4" data-testid="metric-chart-skeleton">
      <gl-skeleton-loader :lines="1" :width="100" />
    </div>
  </div>
</template>
