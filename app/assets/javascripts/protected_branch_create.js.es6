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
      new gl.ProtectedBranchAccessDropdown({
        $dropdown: $allowedToMergeDropdown,
        data: gon.merge_access_levels,
        onSelect: this.onSelectCallback
      });

      // Allowed to Push dropdown
      new gl.ProtectedBranchAccessDropdown({
        $dropdown: $allowedToPushDropdown,
        data: gon.push_access_levels,
        onSelect: this.onSelectCallback
      });

      // Select default
      $allowedToPushDropdown.data('glDropdown').selectRowAtIndex(0);
      $allowedToMergeDropdown.data('glDropdown').selectRowAtIndex(0);

      // Protected branch dropdown
      new ProtectedBranchDropdown({
        $dropdown: this.$wrap.find('.js-protected-branch-select'),
        onSelect: this.onSelectCallback
      });
    }

    // This will run after clicked callback
    onSelect() {

      // Enable submit button
      const $branchInput = this.$wrap.find('input[name="protected_branch[name]"]');
      const $allowedToMergeInput = this.$wrap.find('input[name="protected_branch[merge_access_levels_attributes][0][access_level]"]');
      const $allowedToPushInput = this.$wrap.find('input[name="protected_branch[push_access_levels_attributes][0][access_level]"]');

      if ($branchInput.val() && $allowedToMergeInput.val() && $allowedToPushInput.val()){
        this.$form.find('input[type="submit"]').removeAttr('disabled');
      }
    }
  }

})(window);
