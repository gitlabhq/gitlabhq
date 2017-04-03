/* eslint-disable no-new, arrow-parens, no-param-reassign, comma-dangle, max-len */
/* global Flash */

(global => {
  global.gl = global.gl || {};

  gl.ProtectedTagEdit = class {
    constructor(options) {
      this.$wrap = options.$wrap;
      this.$allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

      this.buildDropdowns();
    }

    buildDropdowns() {
      // Allowed to push dropdown
      new gl.ProtectedTagAccessDropdown({
        $dropdown: this.$allowedToPushDropdown,
        data: gon.push_access_levels,
        onSelect: this.onSelect.bind(this)
      });
    }

    onSelect() {
      const $allowedToPushInput = this.$wrap.find(`input[name="${this.$allowedToPushDropdown.data('fieldName')}"]`);

      // Do not update if one dropdown has not selected any option
      if (!$allowedToPushInput.length) return;

      this.$allowedToPushDropdown.disable();

      $.ajax({
        type: 'POST',
        url: this.$wrap.data('url'),
        dataType: 'json',
        data: {
          _method: 'PATCH',
          protected_tag: {
            push_access_levels_attributes: [{
              id: this.$allowedToPushDropdown.data('access-level-id'),
              access_level: $allowedToPushInput.val()
            }]
          }
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update tag!');
        }
      }).always(() => {
        this.$allowedToPushDropdown.enable();
      });
    }
  };
})(window);
