import { deprecatedCreateFlash as Flash } from '../flash';
import BalsamiqViewer from './balsamiq/balsamiq_viewer';
import { __ } from '~/locale';

function onError() {
  const flash = new Flash(__('Balsamiq file could not be loaded.'));

  return flash;
}

export default function loadBalsamiqFile() {
  const viewer = document.getElementById('js-balsamiq-viewer');

  if (!(viewer instanceof Element)) return;

  const { endpoint } = viewer.dataset;

  const balsamiqViewer = new BalsamiqViewer(viewer);
  balsamiqViewer.loadFile(endpoint).catch(onError);
}
