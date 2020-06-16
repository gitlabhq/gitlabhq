import BindInOut from '../../../../behaviors/bind_in_out';
import Group from '../../../../group';
import initFilePickers from '~/file_pickers';

document.addEventListener('DOMContentLoaded', () => {
  BindInOut.initAll();
  initFilePickers();

  return new Group();
});
