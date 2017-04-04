/* eslint-disable no-new, arrow-parens, no-param-reassign, comma-dangle, max-len */
/* global Flash */

(global => {
  global.gl = global.gl || {};

  gl.ProtectedTagEdit = class {
    constructor(options) {
      this.$wrap = options.$wrap;
      this.$allowedToCreateDropdown = this.$wrap.find('.js-allowed-to-create');

      this.buildDropdowns();
    }

    buildDropdowns() {
      // Allowed to create dropdown
      new gl.ProtectedTagAccessDropdown({
        $dropdown: this.$allowedToCreateDropdown,
        data: gon.create_access_levels,
        onSelect: this.onSelect.bind(this)
      });
    }

    onSelect() {
      const $allowedToCreateInput = this.$wrap.find(`input[name="${this.$allowedToCreateDropdown.data('fieldName')}"]`);

      // Do not update if one dropdown has not selected any option
      if (!$allowedToCreateInput.length) return;

      this.$allowedToCreateDropdown.disable();

      $.ajax({
        type: 'POST',
        url: this.$wrap.data('url'),
        dataType: 'json',
        data: {
          _method: 'PATCH',
          protected_tag: {
            create_access_levels_attributes: [{
              id: this.$allowedToCreateDropdown.data('access-level-id'),
              access_level: $allowedToCreateInput.val()
            }]
          }
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update tag!');
        }
      }).always(() => {
        this.$allowedToCreateDropdown.enable();
      });
    }
  };
})(window);
