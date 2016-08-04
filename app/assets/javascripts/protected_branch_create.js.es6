class ProtectedBranchCreate {
  constructor() {
    this.$wrap = this.$form = $('#new_protected_branch');
    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to Merge dropdowns
    const $allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
    const $allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');

    new ProtectedBranchAccessDropdown({
      $dropdown: $allowedToMergeDropdown,
      data: gon.merge_access_levels,
      onSelect: this.onSelect.bind(this)
    });

    // Select default
    $allowedToMergeDropdown.data('glDropdown').selectRowAtIndex(0);

    // Allowed to Push dropdowns
    new ProtectedBranchAccessDropdown({
      $dropdown: $allowedToPushDropdown,
      data: gon.push_access_levels,
      onSelect: this.onSelect.bind(this)
    });

    // Select default
    $allowedToPushDropdown.data('glDropdown').selectRowAtIndex(0);

    new ProtectedBranchDropdowns({
      $dropdowns: this.$wrap.find('.js-protected-branch-select'),
      onSelect: this.onSelect.bind(this)
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $branchInput = this.$wrap.find('input[name="protected_branch[name]"]');
    const $allowedToMergeInput = this.$wrap.find('input[name="protected_branch[merge_access_level_attributes][access_level]"]');
    const $allowedToPushInput = this.$wrap.find('input[name="protected_branch[push_access_level_attributes][access_level]"]');

    if ($branchInput.val() && $allowedToMergeInput.val() && $allowedToPushInput.val()){
      this.$form.find('[type="submit"]').removeAttr('disabled');
    }
  }
}
