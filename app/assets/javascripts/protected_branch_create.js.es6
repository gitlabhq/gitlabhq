(global => {
  global.gl = global.gl || {};

  const ACCESS_LEVELS = {
    MERGE: 'merge_access_levels',
    PUSH: 'push_access_levels',
  };

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
      new gl.AllowedToMergeDropdown({
        accessLevel: ACCESS_LEVELS.MERGE,
        $dropdown: $allowedToMergeDropdown,
        accessLevelsData: gon.merge_access_levels,
        onSelect: this.onSelectCallback
      });

      // Allowed to Push dropdown
      new gl.AllowedToPushDropdown({
        accessLevel: ACCESS_LEVELS.PUSH,
        $dropdown: $allowedToPushDropdown,
        accessLevelsData: gon.push_access_levels,
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

<<<<<<< HEAD
      this.$form.find('input[type="submit"]').attr('disabled', !($branchInput.val() && $allowedToMergeInputs.length && $allowedToPushInputs.length));
=======
      this.$form.find('input[type="submit"]').attr('disabled', !($branchInput.val() && $allowedToMergeInput.length && $allowedToPushInput.length));
>>>>>>> b2bf01f4c271be66e93ed6f4b48a1da4d50e558d
    }
  }

})(window);
