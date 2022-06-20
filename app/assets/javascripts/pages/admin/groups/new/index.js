import initFilePickers from '~/file_pickers';
import BindInOut from '~/behaviors/bind_in_out';
import Group from '~/group';
import { initGroupNameAndPath } from '~/groups/create_edit_form';

(() => {
  BindInOut.initAll();
  initFilePickers();

  return new Group();
})();

initGroupNameAndPath();
