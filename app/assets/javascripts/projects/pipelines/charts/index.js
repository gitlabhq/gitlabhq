import Vue from 'vue';
import ProjectPipelinesCharts from './components/app.vue';

export default () => {
  const el = document.querySelector('#js-project-pipelines-charts-app');
  const {
    countsFailed,
    countsSuccess,
    countsTotal,
    countsTotalDuration,
    successRatio,
    timesChartLabels,
    timesChartValues,
    lastWeekChartLabels,
    lastWeekChartTotals,
    lastWeekChartSuccess,
    lastMonthChartLabels,
    lastMonthChartTotals,
    lastMonthChartSuccess,
    lastYearChartLabels,
    lastYearChartTotals,
    lastYearChartSuccess,
  } = el.dataset;

  const parseAreaChartData = (labels, totals, success) => ({
    labels: JSON.parse(labels),
    totals: JSON.parse(totals),
    success: JSON.parse(success),
  });

  return new Vue({
    el,
    name: 'ProjectPipelinesChartsApp',
    components: {
      ProjectPipelinesCharts,
    },
    render: createElement =>
      createElement(ProjectPipelinesCharts, {
        props: {
          counts: {
            failed: countsFailed,
            success: countsSuccess,
            total: countsTotal,
            successRatio,
            totalDuration: countsTotalDuration,
          },
          timesChartData: {
            labels: JSON.parse(timesChartLabels),
            values: JSON.parse(timesChartValues),
          },
          lastWeekChartData: parseAreaChartData(
            lastWeekChartLabels,
            lastWeekChartTotals,
            lastWeekChartSuccess,
          ),
          lastMonthChartData: parseAreaChartData(
            lastMonthChartLabels,
            lastMonthChartTotals,
            lastMonthChartSuccess,
          ),
          lastYearChartData: parseAreaChartData(
            lastYearChartLabels,
            lastYearChartTotals,
            lastYearChartSuccess,
          ),
        },
      }),
  });
};
