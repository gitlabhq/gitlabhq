import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import NotebookViewer from './notebook_viewer.vue';

export default ({ el = document.getElementById('js-notebook-viewer'), relativeRawPath }) => {
  return initVueApp({
    el,
    name: 'NotebookViewerRoot',
    provide: {
      relativeRawPath: relativeRawPath || el.dataset.relativeRawPath,
    },
    component: NotebookViewer,
    props: {
      endpoint: el.dataset.endpoint,
    },
  });
};
