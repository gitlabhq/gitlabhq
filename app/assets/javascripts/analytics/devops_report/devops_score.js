import Vue from 'vue';
import DevopsScore from './components/devops_score.vue';

export default () => {
  const el = document.getElementById('js-devops-score');

  if (!el) return false;

  const { devopsScoreMetrics } = el.dataset;

  return new Vue({
    el,
    provide: {
      devopsScoreMetrics: JSON.parse(devopsScoreMetrics),
    },
    render(h) {
      return h(DevopsScore);
    },
  });
};
