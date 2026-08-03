import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ImportHistoryApp from './components/import_history_app.vue';

export function initImportHistory() {
  const el = document.querySelector('#import-history-mount-element');

  if (!el) {
    return null;
  }

  return initVueApp({
    el,
    name: 'ImportHistoryRoot',
    provide: {
      assets: {
        gitlabLogo: el.dataset.logo,
      },
    },
    component: ImportHistoryApp,
  });
}
