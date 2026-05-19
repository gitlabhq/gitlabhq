<script>
import { GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { buildStackedByDimension } from '../../../utils/chart_data';

export default {
  name: 'TwoDimensionsColumnChart',
  components: { GlStackedColumnChart },
  props: {
    data: {
      required: true,
      type: Object,
    },
    primaryDimension: {
      required: true,
      type: Object,
    },
    secondaryDimension: {
      required: true,
      type: Object,
    },
    metric: {
      required: true,
      type: Object,
    },
  },
  computed: {
    chart() {
      return buildStackedByDimension({
        nodes: this.data.nodes,
        primaryDim: this.primaryDimension,
        secondaryDim: this.secondaryDimension,
        metric: this.metric,
      });
    },
  },
};
</script>

<template>
  <gl-stacked-column-chart
    x-axis-type="category"
    :x-axis-title="primaryDimension.label"
    :y-axis-title="metric.label"
    :group-by="chart.groups"
    :bars="chart.bars"
    presentation="stacked"
    :include-legend-avg-max="false"
  />
</template>
