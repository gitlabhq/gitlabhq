import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import LogViewerApp from './log_viewer_app.vue';

export const initJobLogViewer = async () => {
  const el = document.getElementById('js-job-log-viewer');
  const { rawLogPath } = el.dataset;

  return initVueApp({
    el,
    name: 'LogViewerAppRoot',
    component: LogViewerApp,
    props: {
      rawLogPath,
    },
  });
};
