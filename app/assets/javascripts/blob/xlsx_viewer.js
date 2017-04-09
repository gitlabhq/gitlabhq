import XlsxViewer from './xlsx';

document.addEventListener('DOMContentLoaded', () => {
  new XlsxViewer(document.getElementById('js-xlsx-viewer'));
});