<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { calculateRate, generateMetricTableTooltip } from '~/analytics/dashboards/ai_impact/utils';
import { UNITS } from '~/analytics/shared/constants';
import { isNumeric } from '~/lib/utils/number_utils';
import { formatMetric } from '~/analytics/dashboards/utils';

export default {
  name: 'CalculatePercent',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    numerator: {
      type: Number,
      required: true,
      validator: (value) => isNumeric(value),
    },
    denominator: {
      type: Number,
      required: true,
      validator: (value) => isNumeric(value),
    },
  },
  computed: {
    rate() {
      const { numerator, denominator } = this;
      return formatMetric(calculateRate({ numerator, denominator }), UNITS.PERCENT);
    },
    tooltip() {
      const { numerator, denominator } = this;
      return generateMetricTableTooltip({ numerator, denominator });
    },
  },
};
</script>
<template>
  <span v-gl-tooltip="tooltip">{{ rate }}</span>
</template>
