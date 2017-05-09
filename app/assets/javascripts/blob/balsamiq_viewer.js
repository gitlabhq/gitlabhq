import BalsamiqViewer from './balsamiq/balsamiq_viewer';

function loadBalsamiqViewer() {
  const viewer = document.getElementById('js-balsamiq-viewer');
  const endpoint = viewer.dataset.endpoint;

  const balsamiqViewer = new BalsamiqViewer(viewer, endpoint);
  balsamiqViewer.loadFile();
}

$(document).ready(loadBalsamiqViewer);
