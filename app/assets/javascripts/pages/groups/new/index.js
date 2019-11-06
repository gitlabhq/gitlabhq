import $ from 'jquery';
import BindInOut from '~/behaviors/bind_in_out';
import Group from '~/group';
import initAvatarPicker from '~/avatar_picker';
import GroupPathValidator from './group_path_validator';

document.addEventListener('DOMContentLoaded', () => {
  const parentId = $('#group_parent_id');
  if (!parentId.val()) {
    new GroupPathValidator(); // eslint-disable-line no-new
  }
  BindInOut.initAll();
  new Group(); // eslint-disable-line no-new
  initAvatarPicker();
});
