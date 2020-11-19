<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';

export default {
  i18n: {
    noDataMsg: s__(
      'ProductAnalytics|There is no data for this type of chart currently. Please see the Setup tab if you have not configured the product analytics tool already.',
    ),
  },
  components: {
    GlColumnChart,
  },
  inject: {
    formattedData: {
      default: {},
    },
  },
  computed: {
    barSeriesData() {
      return [
        {
          name: 'full',
          data: this.formattedData.keys.map((val, idx) => [val, this.formattedData.values[idx]]),
        },
      ];
    },
  },
};
</script>

<template>
  <div class="gl-xs-w-full">
    <gl-column-chart
      v-if="formattedData.keys"
      :bars="barSeriesData"
      :x-axis-title="__('Value')"
      :y-axis-title="__('Number of events')"
      :x-axis-type="'category'"
    />
    <p v-else data-testid="noActivityChartData">
      {{ $options.i18n.noDataMsg }}
    </p>
  </div>
</template>
