import SketchLoader from './sketch';

export default () => {
  const el = document.getElementById('js-sketch-viewer');

  new SketchLoader(el); // eslint-disable-line no-new
};
