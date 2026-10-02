import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ReportsTabCount from './reports_tab_count.vue';

export default () => {
  const el = document.querySelector('.js-reports-tab-count');

  if (!el) return;

  initVueApp({ el, name: 'MergeRequestReportsTabCountRoot', component: ReportsTabCount });
};
