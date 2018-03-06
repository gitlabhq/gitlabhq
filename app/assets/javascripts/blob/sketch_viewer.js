/* eslint-disable no-new */
import SketchLoader from './sketch';

export default () => {
  const el = document.getElementById('js-sketch-viewer');

  new SketchLoader(el);
};
