import Renderer from './3d_viewer';

export default () => {
  const viewer = new Renderer(document.getElementById('js-stl-viewer'));

  [].slice.call(document.querySelectorAll('.js-material-changer')).forEach((el) => {
    el.addEventListener('click', (e) => {
      const { currentTarget } = e;

      e.preventDefault();

      document.querySelector('.js-material-changer.selected').classList.remove('selected');
      currentTarget.classList.add('selected');
      currentTarget.blur();

      viewer.changeObjectMaterials(currentTarget.dataset.material);
    });
  });
};
