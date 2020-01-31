import Vue from 'vue';
import ProjectPipelinesCharts from './components/app.vue';

export default () => {
  const el = document.querySelector('#js-project-pipelines-charts-app');
  const {
    countsFailed,
    countsSuccess,
    countsTotal,
    successRatio,
    timesChartLabels,
    timesChartValues,
  } = el.dataset;

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
          },
          timesChartData: {
            labels: JSON.parse(timesChartLabels),
            values: JSON.parse(timesChartValues),
          },
        },
      }),
  });
};
