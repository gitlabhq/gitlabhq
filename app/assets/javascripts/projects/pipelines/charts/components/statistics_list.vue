<script>
export default {
  props: {
    counts: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <ul>
    <li>
      <span>{{ s__('PipelineCharts|Total:') }}</span>
      <strong>{{ n__('1 pipeline', '%d pipelines', counts.total) }}</strong>
    </li>
    <li>
      <span>{{ s__('PipelineCharts|Successful:') }}</span>
      <strong>{{ n__('1 pipeline', '%d pipelines', counts.success) }}</strong>
    </li>
    <li>
      <span>{{ s__('PipelineCharts|Failed:') }}</span>
      <strong>{{ n__('1 pipeline', '%d pipelines', counts.failed) }}</strong>
    </li>
    <li>
      <span>{{ s__('PipelineCharts|Success ratio:') }}</span>
      <strong>{{ counts.successRatio }}%</strong>
    </li>
  </ul>
</template>
