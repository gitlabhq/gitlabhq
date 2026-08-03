import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DevopsScore from './components/devops_score.vue';

export default () => {
  const el = document.getElementById('js-devops-score');

  if (!el) return false;

  const { devopsScoreMetrics } = el.dataset;

  return initVueApp({
    el,
    name: 'DevopsScoreRoot',
    provide: {
      devopsScoreMetrics: JSON.parse(devopsScoreMetrics),
    },
    component: DevopsScore,
  });
};
