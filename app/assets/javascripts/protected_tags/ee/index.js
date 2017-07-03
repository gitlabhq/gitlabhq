/* eslint-disable no-param-reassign */
import ProtectedTagCreate from './protected_tag_create';
import ProtectedTagEditList from './protected_tag_edit_list';

((global) => {
  global.gl = global.gl || {};

  gl.ProtectedTagCreate = ProtectedTagCreate;
  gl.ProtectedTagEditList = ProtectedTagEditList;
})(window);
