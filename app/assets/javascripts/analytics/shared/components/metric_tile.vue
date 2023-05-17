<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import MetricPopover from './metric_popover.vue';

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
      const parsedFloat = parseFloat(this.metric.value);
      return Number.isNaN(parsedFloat) || Number.isInteger(parsedFloat) ? 0 : 1;
    },
    hasLinks() {
      return this.metric.links?.length && this.metric.links[0].url;
    },
  },
  methods: {
    clickHandler({ links }) {
      if (this.hasLinks) {
        redirectTo(links[0].url); // eslint-disable-line import/no-deprecated
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
      :class="{ 'gl-hover-cursor-pointer': hasLinks }"
      tabindex="0"
      @click="clickHandler(metric)"
    />
    <metric-popover :metric="metric" :target="metric.identifier" />
  </div>
</template>
