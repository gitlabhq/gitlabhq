<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import StatisticsList from './statistics_list.vue';
import {
  CHART_CONTAINER_HEIGHT,
  INNER_CHART_HEIGHT,
  X_AXIS_LABEL_ROTATION,
  X_AXIS_TITLE_OFFSET,
} from '../constants';

export default {
  components: {
    StatisticsList,
    GlColumnChart,
  },
  props: {
    counts: {
      type: Object,
      required: true,
    },
    timesChartData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      timesChartTransformedData: {
        full: this.mergeLabelsAndValues(this.timesChartData.labels, this.timesChartData.values),
      },
    };
  },
  methods: {
    mergeLabelsAndValues(labels, values) {
      return labels.map((label, index) => [label, values[index]]);
    },
  },
  chartContainerHeight: CHART_CONTAINER_HEIGHT,
  timesChartOptions: {
    height: INNER_CHART_HEIGHT,
    xAxis: {
      axisLabel: {
        rotate: X_AXIS_LABEL_ROTATION,
      },
      nameGap: X_AXIS_TITLE_OFFSET,
    },
  },
};
</script>
<template>
  <div>
    <h4 class="my-4">{{ s__('PipelineCharts|Overall statistics') }}</h4>
    <div class="row">
      <div class="col-md-6">
        <statistics-list :counts="counts" />
      </div>
      <div class="col-md-6">
        <strong>
          {{ __('Duration for the last 30 commits') }}
        </strong>
        <gl-column-chart
          :height="$options.chartContainerHeight"
          :option="$options.timesChartOptions"
          :data="timesChartTransformedData"
          :y-axis-title="__('Minutes')"
          :x-axis-title="__('Commit')"
          x-axis-type="category"
        />
      </div>
    </div>
  </div>
</template>
