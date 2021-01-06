<script>
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { s__, n__ } from '~/locale';

const defaultPrecision = 2;

export default {
  props: {
    counts: {
      type: Object,
      required: true,
    },
  },
  computed: {
    statistics() {
      const formatter = getFormatter(SUPPORTED_FORMATS.percentHundred);

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
          value: formatter(this.counts.successRatio, defaultPrecision),
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
