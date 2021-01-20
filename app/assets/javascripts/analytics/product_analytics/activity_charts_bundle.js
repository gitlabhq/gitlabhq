import Vue from 'vue';
import ActivityChart from './components/activity_chart.vue';

export default () => {
  const containers = document.querySelectorAll('.js-project-analytics-chart');

  if (!containers) {
    return false;
  }

  return containers.forEach((container) => {
    const { chartData } = container.dataset;
    const formattedData = JSON.parse(chartData);

    return new Vue({
      el: container,
      components: {
        ActivityChart,
      },
      provide: {
        formattedData,
      },
      render(createElement) {
        return createElement('activity-chart');
      },
    });
  });
};
