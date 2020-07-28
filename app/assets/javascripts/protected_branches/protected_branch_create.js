import $ from 'jquery';
import ProtectedBranchAccessDropdown from './protected_branch_access_dropdown';
import CreateItemDropdown from '../create_item_dropdown';
import AccessorUtilities from '../lib/utils/accessor';
import { __ } from '~/locale';

export default class ProtectedBranchCreate {
  constructor() {
    this.$form = $('.js-new-protected-branch');
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    this.currentProjectUserDefaults = {};
    this.buildDropdowns();
  }

  buildDropdowns() {
    const $allowedToMergeDropdown = this.$form.find('.js-allowed-to-merge');
    const $allowedToPushDropdown = this.$form.find('.js-allowed-to-push');
    const $protectedBranchDropdown = this.$form.find('.js-protected-branch-select');

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

    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: $protectedBranchDropdown,
      defaultToggleLabel: __('Protected Branch'),
      fieldName: 'protected_branch[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedBranchCreate.getProtectedBranches,
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $branchInput = this.$form.find('input[name="protected_branch[name]"]');
    const $allowedToMergeInput = this.$form.find(
      'input[name="protected_branch[merge_access_levels_attributes][0][access_level]"]',
    );
    const $allowedToPushInput = this.$form.find(
      'input[name="protected_branch[push_access_levels_attributes][0][access_level]"]',
    );
    const completedForm = !(
      $branchInput.val() &&
      $allowedToMergeInput.length &&
      $allowedToPushInput.length
    );

    this.$form.find('input[type="submit"]').prop('disabled', completedForm);
  }

  static getProtectedBranches(term, callback) {
    callback(gon.open_branches);
  }
}
