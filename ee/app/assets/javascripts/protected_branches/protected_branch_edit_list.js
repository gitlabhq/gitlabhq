/* eslint-disable no-new */

import $ from 'jquery';
import ProtectedBranchEdit from './protected_branch_edit';

export default class ProtectedBranchEditList {
  constructor() {
    this.$wrap = $('.protected-branches-list');
    this.initEditForm();
  }

  initEditForm() {
    // Build edit forms
    this.$wrap.find('.js-protected-branch-edit-form').each((i, el) => {
      new ProtectedBranchEdit({
        $wrap: $(el),
      });
    });
  }
}
