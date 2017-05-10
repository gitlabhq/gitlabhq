import BalsamiqViewer from './balsamiq/balsamiq_viewer';

function loadBalsamiqViewer() {
  const viewer = document.getElementById('js-balsamiq-viewer');

  if (!(viewer instanceof Element)) return;

  const endpoint = viewer.dataset.endpoint;

  const balsamiqViewer = new BalsamiqViewer(viewer);
  balsamiqViewer.loadFile(endpoint);
}

$(loadBalsamiqViewer);
