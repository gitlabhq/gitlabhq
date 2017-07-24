import ProtectedBranchAccessDropdown from './protected_branch_access_dropdown';
import ProtectedBranchDropdown from './protected_branch_dropdown';

export default class ProtectedBranchCreate {
  constructor() {
    this.$form = $('.js-new-protected-branch');
    this.buildDropdowns();
  }

  buildDropdowns() {
    const $allowedToMergeDropdown = this.$form.find('.js-allowed-to-merge');
    const $allowedToPushDropdown = this.$form.find('.js-allowed-to-push');

    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Merge dropdown
    this.protectedBranchMergeAccessDropdown = new ProtectedBranchAccessDropdown({
      $dropdown: $allowedToMergeDropdown,
      data: gon.merge_access_levels,
      onSelect: this.onSelectCallback,
    });

    // Allowed to Push dropdown
    this.protectedBranchPushAccessDropdown = new ProtectedBranchAccessDropdown({
      $dropdown: $allowedToPushDropdown,
      data: gon.push_access_levels,
      onSelect: this.onSelectCallback,
    });

    // Select default
    $allowedToPushDropdown.data('glDropdown').selectRowAtIndex(0);
    $allowedToMergeDropdown.data('glDropdown').selectRowAtIndex(0);

    // Protected branch dropdown
    this.protectedBranchDropdown = new ProtectedBranchDropdown({
      $dropdown: this.$form.find('.js-protected-branch-select'),
      onSelect: this.onSelectCallback,
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $branchInput = this.$form.find('input[name="protected_branch[name]"]');
    const $allowedToMergeInput = this.$form.find('input[name="protected_branch[merge_access_levels_attributes][0][access_level]"]');
    const $allowedToPushInput = this.$form.find('input[name="protected_branch[push_access_levels_attributes][0][access_level]"]');

    this.$form.find('input[type="submit"]').attr('disabled', !($branchInput.val() && $allowedToMergeInput.length && $allowedToPushInput.length));
  }
}
