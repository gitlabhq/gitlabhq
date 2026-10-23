import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import StatisticsPanelApp from './components/app.vue';

export default function initStatisticsPanel(el) {
  if (!el) {
    return false;
  }

  return initVueApp({
    el,
    name: 'StatisticsPanelAppRoot',
    pinia,
    component: StatisticsPanelApp,
  });
}
