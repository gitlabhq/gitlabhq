/* eslint-disable no-new */
import SketchLoader from './sketch';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('js-sketch-viewer');

  new SketchLoader(el);
});
