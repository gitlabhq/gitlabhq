import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import StatisticsPanelApp from './components/app.vue';
import createStore from './store';

export default function initStatisticsPanel(el) {
  if (!el) {
    return false;
  }

  const store = createStore();

  return initVueApp({
    el,
    name: 'StatisticsPanelAppRoot',
    store,
    component: StatisticsPanelApp,
  });
}
