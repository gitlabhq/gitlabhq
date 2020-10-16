<script>
import InstanceCounts from './instance_counts.vue';
import PipelinesChart from './pipelines_chart.vue';

export default {
  name: 'InstanceStatisticsApp',
  components: {
    InstanceCounts,
    PipelinesChart,
  },
};
</script>

<template>
  <div>
    <instance-counts />
    <pipelines-chart />
  </div>
</template>
