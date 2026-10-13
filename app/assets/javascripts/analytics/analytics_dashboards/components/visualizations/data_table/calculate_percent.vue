<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { calculateRate, generateMetricTableTooltip } from '~/analytics/dashboards/ai_impact/utils';
import { UNITS } from '~/analytics/shared/constants';
import { isNumeric } from '~/lib/utils/number_utils';
import { formatMetric } from '~/analytics/dashboards/utils';
import { formatNumber } from '~/locale';

// How the rate renders: the percentage alone, or the numerator at full size with the
// percentage beside it as subtext.
export const PERCENT_VARIANTS = {
  PERCENT: 'PERCENT',
  NUMERATOR_WITH_PERCENT: 'NUMERATOR_WITH_PERCENT',
};

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
    variant: {
      type: String,
      required: false,
      default: PERCENT_VARIANTS.PERCENT,
      validator: (value) => Object.values(PERCENT_VARIANTS).includes(value),
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
    showsNumerator() {
      return this.variant === PERCENT_VARIANTS.NUMERATOR_WITH_PERCENT;
    },
    formattedNumerator() {
      return formatNumber(this.numerator);
    },
  },
};
</script>
<template>
  <span v-if="showsNumerator"
    >{{ formattedNumerator
    }}<span v-gl-tooltip="tooltip" class="gl-ml-3 gl-text-sm gl-font-normal gl-text-subtle">{{
      rate
    }}</span></span
  >
  <span v-else v-gl-tooltip="tooltip">{{ rate }}</span>
</template>
