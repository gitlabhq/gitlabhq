(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchCreate = class {
    constructor() {
      this.$wrap = this.$form = $('#new_protected_branch');
      this.buildDropdowns();
    }

    buildDropdowns() {
      const $allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
      const $allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

      // Cache callback
      this.onSelectCallback = this.onSelect.bind(this);

      // Allowed to Merge dropdown
      new gl.allowedToMergeDropdown({
        $dropdown: $allowedToMergeDropdown,
        data: gon.merge_access_levels,
        onSelect: this.onSelectCallback
      });

      // Allowed to Push dropdown
      new gl.allowedToPushDropdown({
        $dropdown: $allowedToPushDropdown,
        data: gon.push_access_levels,
        onSelect: this.onSelectCallback
      });

      // Protected branch dropdown
      new gl.ProtectedBranchDropdown({
        $dropdown: this.$wrap.find('.js-protected-branch-select'),
        onSelect: this.onSelectCallback
      });
    }

    // Enable submit button after selecting an option
    onSelect() {
      const $branchInput = this.$wrap.find('input[name="protected_branch[name]"]');
      const $allowedToMergeInputs = this.$wrap.find('input[name^="protected_branch[merge_access_levels_attributes]"]');
      const $allowedToPushInputs = this.$wrap.find('input[name^="protected_branch[push_access_levels_attributes]"]');

      this.$form.find('input[type="submit"]').attr('disabled', !($branchInput.val() && $allowedToMergeInputs.length && $allowedToPushInputs.length));
    }
  }

})(window);
