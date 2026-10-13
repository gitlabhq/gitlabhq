<script>
import { GlAreaChart } from '@gitlab/ui/src/charts';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

export default {
  name: 'ContributorAreaChart',
  components: {
    GlAreaChart,
  },
  props: {
    data: {
      type: Array,
      required: true,
    },
    option: {
      type: Object,
      required: true,
    },
    height: {
      type: Number,
      required: true,
    },
  },
  emits: ['created'],
  data() {
    return {
      tooltipTitle: '',
      tooltipValues: [],
    };
  },
  computed: {
    tooltipLabel() {
      return this.option.yAxis?.name || __('Value');
    },
  },
  methods: {
    formatTooltipText({ seriesData }) {
      const [dateTime] = seriesData[0].data;
      this.tooltipTitle = localeDateFormat.asDate.format(newDate(dateTime));
      this.tooltipValues = seriesData.map(({ seriesName, data }) => ({
        label: seriesName || this.tooltipLabel,
        value: data[1],
      }));
    },
  },
};
</script>

<template>
  <gl-area-chart
    responsive
    width="auto"
    :data="data"
    :option="option"
    :height="height"
    :format-tooltip-text="formatTooltipText"
    @created="$emit('created', $event)"
  >
    <template #tooltip-title>
      <div data-testid="tooltip-title">{{ tooltipTitle }}</div>
    </template>

    <template #tooltip-content>
      <div
        v-for="({ label, value }, index) in tooltipValues"
        :key="`${label}-${index}`"
        class="gl-flex gl-justify-between gl-gap-6"
      >
        <span data-testid="tooltip-label">{{ label }}</span>
        <span data-testid="tooltip-value">{{ value }}</span>
      </div>
    </template>
  </gl-area-chart>
</template>
