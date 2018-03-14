/* eslint-disable no-new */

import $ from 'jquery';
import ProtectedTagEdit from './protected_tag_edit';

export default class ProtectedTagEditList {
  constructor() {
    this.$wrap = $('.protected-tags-list');
    this.initEditForm();
  }

  initEditForm() {
    this.$wrap.find('.js-protected-tag-edit-form').each((i, el) => {
      new ProtectedTagEdit({
        $wrap: $(el),
      });
    });
  }
}
