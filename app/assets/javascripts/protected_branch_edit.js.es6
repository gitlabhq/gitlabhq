(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchEdit = class {
    constructor(options) {
      this.$wrap = options.$wrap;
      this.$allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
      this.$allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

      this.buildDropdowns();
    }

    buildDropdowns() {

      // Allowed to merge dropdown
      new gl.ProtectedBranchAccessDropdown({
        $dropdown: this.$allowedToMergeDropdown,
        data: gon.merge_access_levels,
        onSelect: this.onSelect.bind(this)
      });

      // Allowed to push dropdown
      new gl.ProtectedBranchAccessDropdown({
        $dropdown: this.$allowedToPushDropdown,
        data: gon.push_access_levels,
        onSelect: this.onSelect.bind(this)
      });
    }

    onSelect() {
      const $allowedToMergeInput = this.$wrap.find(`input[name="${this.$allowedToMergeDropdown.data('fieldName')}"]`);
      const $allowedToPushInput = this.$wrap.find(`input[name="${this.$allowedToPushDropdown.data('fieldName')}"]`);

      $.ajax({
        type: 'POST',
        url: this.$wrap.data('url'),
        dataType: 'json',
        data: {
          _method: 'PATCH',
          id: this.$wrap.data('banchId'),
          protected_branch: {
            merge_access_levels_attributes: [{
              id: this.$allowedToMergeDropdown.data('access-level-id'),
              access_level: $allowedToMergeInput.val()
            }],
            push_access_levels_attributes: [{
              id: this.$allowedToPushDropdown.data('access-level-id'),
              access_level: $allowedToPushInput.val()
            }]
          }
        },
        success: () => {
          this.$wrap.effect('highlight');
        },
        error() {
          $.scrollTo(0);
          new Flash('Failed to update branch!');
        }
      });
    }
  }

})(window);
