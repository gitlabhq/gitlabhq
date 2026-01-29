import Vue from 'vue';
import PdfViewer from './pdf_viewer.vue';

export default () => {
  const el = document.getElementById('js-pdf-viewer');

  return new Vue({
    el,
    name: 'PdfViewerRoot',
    render(createElement) {
      return createElement(PdfViewer, {
        props: {
          pdf: el.dataset.endpoint,
        },
      });
    },
  });
};
