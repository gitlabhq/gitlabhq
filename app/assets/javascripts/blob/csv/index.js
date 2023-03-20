import Vue from 'vue';
import CsvViewer from './csv_viewer.vue';

export default () => {
  const el = document.getElementById('js-csv-viewer');

  return new Vue({
    el,
    render(createElement) {
      return createElement(CsvViewer, {
        props: {
          csv: el.dataset.data,
          remoteFile: true,
        },
      });
    },
  });
};
