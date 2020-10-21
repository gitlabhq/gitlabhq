<script>
import InstanceCounts from './instance_counts.vue';
import PipelinesChart from './pipelines_chart.vue';
import UsersChart from './users_chart.vue';
import { TODAY, TOTAL_DAYS_TO_SHOW, START_DATE } from '../constants';

export default {
  name: 'InstanceStatisticsApp',
  components: {
    InstanceCounts,
    PipelinesChart,
    UsersChart,
  },
  TOTAL_DAYS_TO_SHOW,
  START_DATE,
  TODAY,
};
</script>

<template>
  <div>
    <instance-counts />
    <users-chart
      :start-date="$options.START_DATE"
      :end-date="$options.TODAY"
      :total-data-points="$options.TOTAL_DAYS_TO_SHOW"
    />
    <pipelines-chart />
  </div>
</template>
