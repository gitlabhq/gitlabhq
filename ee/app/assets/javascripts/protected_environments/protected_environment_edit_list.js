/* eslint-disable no-new */

import $ from 'jquery';
import ProtectedEnvironmentEdit from './protected_environment_edit';

export default class ProtectedEnvironmentEditList {
  constructor() {
    this.$wrap = $('.protected-environments-list');
    this.initEditForm();
  }

  initEditForm() {
    this.$wrap.find('.js-protected-environment-edit-form').each((i, el) => {
      new ProtectedEnvironmentEdit({
        $wrap: $(el),
      });
    });
  }
}

