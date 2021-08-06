import Vue from 'vue';
import DevopsScore from './components/devops_score.vue';

export default () => {
  const el = document.getElementById('js-devops-score');

  if (!el) return false;

  const {
    devopsScoreMetrics,
    devopsReportDocsPath,
    noDataImagePath,
    devopsScoreIntroImagePath,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      devopsScoreMetrics: JSON.parse(devopsScoreMetrics),
      devopsReportDocsPath,
      noDataImagePath,
      devopsScoreIntroImagePath,
    },
    render(h) {
      return h(DevopsScore);
    },
  });
};
