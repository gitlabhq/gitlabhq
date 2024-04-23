import Vue from 'vue';
import LogViewerApp from './log_viewer_app.vue';

export const initJobLogViewer = async () => {
  const el = document.getElementById('js-job-log-viewer');
  const { rawLogPath } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(LogViewerApp, {
        props: {
          rawLogPath,
        },
      });
    },
  });
};
