import DXFRenderer from './dxf';

document.addEventListener('DOMContentLoaded', () => {
  const viewer = new DXFRenderer(document.getElementById('js-dxf-viewer'));
  console.log('viewer',viewer)
});
