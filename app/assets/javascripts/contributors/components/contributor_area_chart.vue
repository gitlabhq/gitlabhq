<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
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
  data() {
    return {
      tooltipTitle: '',
      tooltipValue: [],
    };
  },
  computed: {
    tooltipLabel() {
      return this.option.yAxis?.name || __('Value');
    },
  },
  methods: {
    formatTooltipText({ seriesData }) {
      const [dateTime, value] = seriesData[0].data;
      this.tooltipTitle = localeDateFormat.asDate.format(newDate(dateTime));
      this.tooltipValue = value;
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
      <div class="gl-flex gl-justify-between gl-gap-6">
        <span data-testid="tooltip-label">{{ tooltipLabel }}</span>
        <span data-testid="tooltip-value">{{ tooltipValue }}</span>
      </div>
    </template>
  </gl-area-chart>
</template>
