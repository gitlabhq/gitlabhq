import initFilePickers from '~/file_pickers';
import BindInOut from '../../../../behaviors/bind_in_out';
import Group from '../../../../group';

document.addEventListener('DOMContentLoaded', () => {
  BindInOut.initAll();
  initFilePickers();

  return new Group();
});
