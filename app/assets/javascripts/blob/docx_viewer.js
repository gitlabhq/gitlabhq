import DocxRenderer from './docx';

document.addEventListener('DOMContentLoaded', () => {
  const viewer = new DocxRenderer(document.getElementById('js-docx-viewer'));
  console.log('viewer',viewer)
});