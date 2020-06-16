import $ from 'jquery';
import BindInOut from '~/behaviors/bind_in_out';
import Group from '~/group';
import GroupPathValidator from './group_path_validator';
import initFilePickers from '~/file_pickers';

document.addEventListener('DOMContentLoaded', () => {
  const parentId = $('#group_parent_id');
  if (!parentId.val()) {
    new GroupPathValidator(); // eslint-disable-line no-new
  }
  BindInOut.initAll();
  initFilePickers();

  return new Group();
});
