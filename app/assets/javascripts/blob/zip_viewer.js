/* eslint-disable no-new */
import ZipRender from './zip';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('js-zip-viewer');
  new ZipRender(el);
});
