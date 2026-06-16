<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { UNITS } from '~/analytics/shared/constants';
import TrendIndicator from '../../../../dashboards/components/trend_indicator.vue';
import { formatMetric } from '../../../../dashboards/utils';
import { TREND_STYLES, TREND_STYLE_ASC } from '../../../../dashboards/constants';

export default {
  name: 'ChangePercentageIndicator',
  components: {
    TrendIndicator,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: [String, Number],
      required: true,
    },
    tooltip: {
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
    formatInvalidTrend() {
      return this.value === 0 ? formatMetric(0, UNITS.PERCENT) : this.value;
    },
    isValidTrend() {
      return typeof this.value === 'number' && this.value !== 0;
    },
  },
};
</script>
<template>
  <div>
    <trend-indicator v-if="isValidTrend" :change="value" :trend-style="trendStyle" />
    <span
      v-else
      v-gl-tooltip="tooltip"
      :aria-label="tooltip"
      class="gl-cursor-pointer gl-text-sm gl-text-subtle hover:gl-underline"
      data-testid="metric-cell-no-change"
      tabindex="0"
    >
      {{ formatInvalidTrend }}
    </span>
  </div>
</template>
