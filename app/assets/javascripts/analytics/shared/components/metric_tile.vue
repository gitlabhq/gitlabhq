<script>
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { countFloatingPointDigits } from '~/lib/utils/number_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { generateMetricLink } from '~/analytics/shared/utils';
import { FLOW_METRICS } from '~/analytics/shared/constants';
import MetricPopover from './metric_popover.vue';

const MAX_DISPLAYED_DECIMAL_PRECISION = 2;

export default {
  name: 'MetricTile',
  components: {
    GlSingleStat,
    MetricPopover,
  },
  props: {
    metric: {
      type: Object,
      required: true,
    },
    namespacePath: {
      type: String,
      required: true,
    },
    isProjectNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    decimalPlaces() {
      const { value } = this.metric;
      const parsedFloat = parseFloat(value);

      if (!Number.isNaN(parsedFloat) && !Number.isInteger(parsedFloat)) {
        return Math.min(countFloatingPointDigits(value), MAX_DISPLAYED_DECIMAL_PRECISION);
      }
      return 0;
    },
    metricUrl() {
      const { metric, namespacePath, isProjectNamespace } = this;
      const { LEAD_TIME, CYCLE_TIME } = FLOW_METRICS;

      // Both of these metrics drill down to VSA, so we return an empty string here
      // to avoid circular redirect
      if ([LEAD_TIME, CYCLE_TIME].includes(metric.identifier)) return '';

      return generateMetricLink({ metricId: metric.identifier, namespacePath, isProjectNamespace });
    },
  },
  methods: {
    clickHandler() {
      if (this.metricUrl) {
        visitUrl(this.metricUrl);
      }
    },
  },
};
</script>
<template>
  <div v-bind="$attrs">
    <gl-single-stat
      :id="metric.identifier"
      :value="`${metric.value}`"
      :title="metric.label"
      :unit="metric.unit || ''"
      :should-animate="true"
      :animation-decimal-places="decimalPlaces"
      :class="{ 'hover:gl-cursor-pointer': metricUrl }"
      data-testid="metric-tile"
      tabindex="0"
      use-delimiters
      @click="clickHandler"
    />
    <metric-popover :metric="metric" :metric-url="metricUrl" :target="metric.identifier" />
  </div>
</template>
