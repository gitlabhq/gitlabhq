/* eslint-disable no-new, arrow-parens, no-param-reassign, comma-dangle, max-len */
/* global ProtectedTagDropdown */

(global => {
  global.gl = global.gl || {};

  gl.ProtectedTagCreate = class {
    constructor() {
      this.$wrap = this.$form = $('.new_protected_tag');
      this.buildDropdowns();
    }

    buildDropdowns() {
      const $allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

      // Cache callback
      this.onSelectCallback = this.onSelect.bind(this);

      // Allowed to Push dropdown
      new gl.ProtectedTagAccessDropdown({
        $dropdown: $allowedToPushDropdown,
        data: gon.push_access_levels,
        onSelect: this.onSelectCallback
      });

      // Select default
      $allowedToPushDropdown.data('glDropdown').selectRowAtIndex(0);

      // Protected tag dropdown
      new ProtectedTagDropdown({
        $dropdown: this.$wrap.find('.js-protected-tag-select'),
        onSelect: this.onSelectCallback
      });
    }

    // This will run after clicked callback
    onSelect() {
      // Enable submit button
      const $tagInput = this.$wrap.find('input[name="protected_tag[name]"]');
      const $allowedToPushInput = this.$wrap.find('input[name="protected_tag[push_access_levels_attributes][0][access_level]"]');

      this.$form.find('input[type="submit"]').attr('disabled', !($tagInput.val() && $allowedToPushInput.length));
    }
  };
})(window);
