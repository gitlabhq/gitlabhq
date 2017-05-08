import BalsamiqViewer from './balsamiq/balsamiq_viewer';

function loadBalsamiqViewer() {
  const balsamiqViewer = new BalsamiqViewer(document.getElementById('js-balsamiq-viewer'));
  balsamiqViewer.loadFile();
}

$(document).ready(loadBalsamiqViewer);
