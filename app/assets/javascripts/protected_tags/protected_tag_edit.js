/* eslint-disable no-new */
/* global Flash */

import ProtectedTagAccessDropdown from './protected_tag_access_dropdown';

export default class ProtectedTagEdit {
  constructor(options) {
    this.$wrap = options.$wrap;
    this.$allowedToCreateDropdownButton = this.$wrap.find('.js-allowed-to-create');
    this.onSelectCallback = this.onSelect.bind(this);

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to create dropdown
    this.protectedTagAccessDropdown = new ProtectedTagAccessDropdown({
      $dropdown: this.$allowedToCreateDropdownButton,
      data: gon.create_access_levels,
      onSelect: this.onSelectCallback,
    });
  }

  onSelect() {
    const $allowedToCreateInput = this.$wrap.find(`input[name="${this.$allowedToCreateDropdownButton.data('fieldName')}"]`);

    // Do not update if one dropdown has not selected any option
    if (!$allowedToCreateInput.length) return;

    this.$allowedToCreateDropdownButton.disable();

    $.ajax({
      type: 'POST',
      url: this.$wrap.data('url'),
      dataType: 'json',
      data: {
        _method: 'PATCH',
        protected_tag: {
          create_access_levels_attributes: [{
            id: this.$allowedToCreateDropdownButton.data('access-level-id'),
            access_level: $allowedToCreateInput.val(),
          }],
        },
      },
      error() {
        new Flash('Failed to update tag!', null, $('.js-protected-tags-list'));
      },
    }).always(() => {
      this.$allowedToCreateDropdownButton.enable();
    });
  }
}
