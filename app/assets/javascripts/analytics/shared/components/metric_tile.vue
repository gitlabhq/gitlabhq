<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { countFloatingPointDigits } from '~/lib/utils/number_utils';
import { visitUrl } from '~/lib/utils/url_utility';
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
    hasLinks() {
      return this.metric.links?.length && this.metric.links[0].url;
    },
  },
  methods: {
    clickHandler({ links }) {
      if (this.hasLinks) {
        visitUrl(links[0].url);
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
      :class="{ 'hover:gl-cursor-pointer': hasLinks }"
      data-testid="metric-tile"
      tabindex="0"
      use-delimiters
      @click="clickHandler(metric)"
    />
    <metric-popover :metric="metric" :target="metric.identifier" />
  </div>
</template>
