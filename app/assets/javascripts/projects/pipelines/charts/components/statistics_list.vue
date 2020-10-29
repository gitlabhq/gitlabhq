<script>
import { formatTime } from '~/lib/utils/datetime_utility';
import { s__, n__ } from '~/locale';

export default {
  props: {
    counts: {
      type: Object,
      required: true,
    },
  },
  computed: {
    totalDuration() {
      return formatTime(this.counts.totalDuration);
    },
    statistics() {
      return [
        {
          title: s__('PipelineCharts|Total:'),
          value: n__('1 pipeline', '%d pipelines', this.counts.total),
        },
        {
          title: s__('PipelineCharts|Successful:'),
          value: n__('1 pipeline', '%d pipelines', this.counts.success),
        },
        {
          title: s__('PipelineCharts|Failed:'),
          value: n__('1 pipeline', '%d pipelines', this.counts.failed),
        },
        {
          title: s__('PipelineCharts|Success ratio:'),
          value: `${this.counts.successRatio}%`,
        },
        {
          title: s__('PipelineCharts|Total duration:'),
          value: this.totalDuration,
        },
      ];
    },
  },
};
</script>
<template>
  <ul>
    <template v-for="({ title, value }, index) in statistics">
      <li :key="index">
        <span>{{ title }}</span>
        <strong>{{ value }}</strong>
      </li>
    </template>
  </ul>
</template>
