import Renderer from './3d_viewer';

export default () => {
  const viewer = new Renderer(document.getElementById('js-stl-viewer'));

  [].slice.call(document.querySelectorAll('.js-material-changer')).forEach((el) => {
    el.addEventListener('click', (e) => {
      const { target } = e;

      e.preventDefault();

      document.querySelector('.js-material-changer.selected').classList.remove('selected');
      target.classList.add('selected');
      target.blur();

      viewer.changeObjectMaterials(target.dataset.type);
    });
  });
};
