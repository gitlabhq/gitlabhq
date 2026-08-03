import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import PdfViewer from './pdf_viewer.vue';

export default () => {
  const el = document.getElementById('js-pdf-viewer');

  return initVueApp({
    el,
    name: 'PdfViewerRoot',
    component: PdfViewer,
    props: {
      pdf: el.dataset.endpoint,
    },
  });
};
