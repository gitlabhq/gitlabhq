import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import CsvViewer from './csv_viewer.vue';

export default () => {
  const el = document.getElementById('js-csv-viewer');

  return initVueApp({
    el,
    name: 'CsvViewerRoot',
    component: CsvViewer,
    props: {
      csv: el.dataset.data,
      remoteFile: true,
    },
  });
};
