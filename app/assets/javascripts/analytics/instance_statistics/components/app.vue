<script>
import InstanceCounts from './instance_counts.vue';
import InstanceStatisticsCountChart from './instance_statistics_count_chart.vue';
import UsersChart from './users_chart.vue';
import ProjectsAndGroupsChart from './projects_and_groups_chart.vue';
import ChartsConfig from './charts_config';
import { TODAY, TOTAL_DAYS_TO_SHOW, START_DATE } from '../constants';

export default {
  name: 'InstanceStatisticsApp',
  components: {
    InstanceCounts,
    InstanceStatisticsCountChart,
    UsersChart,
    ProjectsAndGroupsChart,
  },
  TOTAL_DAYS_TO_SHOW,
  START_DATE,
  TODAY,
  configs: ChartsConfig,
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
    <projects-and-groups-chart
      :start-date="$options.START_DATE"
      :end-date="$options.TODAY"
      :total-data-points="$options.TOTAL_DAYS_TO_SHOW"
    />
    <instance-statistics-count-chart
      v-for="chartOptions in $options.configs"
      :key="chartOptions.chartTitle"
      :queries="chartOptions.queries"
      :x-axis-title="chartOptions.xAxisTitle"
      :y-axis-title="chartOptions.yAxisTitle"
      :load-chart-error-message="chartOptions.loadChartError"
      :no-data-message="chartOptions.noDataMessage"
      :chart-title="chartOptions.chartTitle"
    />
  </div>
</template>
