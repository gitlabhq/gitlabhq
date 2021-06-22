import createFlash from '~/flash';
import { __ } from '~/locale';
import BalsamiqViewer from './balsamiq/balsamiq_viewer';

function onError() {
  const flash = createFlash({
    message: __('Balsamiq file could not be loaded.'),
  });

  return flash;
}

export default function loadBalsamiqFile() {
  const viewer = document.getElementById('js-balsamiq-viewer');

  if (!(viewer instanceof Element)) return;

  const { endpoint } = viewer.dataset;

  const balsamiqViewer = new BalsamiqViewer(viewer);
  balsamiqViewer.loadFile(endpoint).catch(onError);
}
