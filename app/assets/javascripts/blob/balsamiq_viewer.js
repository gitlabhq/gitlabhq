import BalsamiqViewer from './balsamiq/balsamiq_viewer';

document.addEventListener('DOMContentLoaded', () => {
  const balsamiqViewer = new BalsamiqViewer(document.getElementById('js-balsamiq-viewer'));
  balsamiqViewer.loadFile();
});
