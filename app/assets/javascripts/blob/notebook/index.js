import Vue from 'vue';
import NotebookViewer from './notebook_viewer.vue';

export default ({ el = document.getElementById('js-notebook-viewer'), relativeRawPath }) => {
  return new Vue({
    el,
    provide: {
      relativeRawPath: relativeRawPath || el.dataset.relativeRawPath,
    },
    render(createElement) {
      return createElement(NotebookViewer, {
        props: {
          endpoint: el.dataset.endpoint,
        },
      });
    },
  });
};
