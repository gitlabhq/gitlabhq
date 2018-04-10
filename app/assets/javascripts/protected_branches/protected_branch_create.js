import $ from 'jquery';
import _ from 'underscore';
import ProtectedBranchAccessDropdown from './protected_branch_access_dropdown';
import CreateItemDropdown from '../create_item_dropdown';
import AccessorUtilities from '../lib/utils/accessor';

const PB_LOCAL_STORAGE_KEY = 'protected-branches-defaults';

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
      defaultToggleLabel: 'Protected Branch',
      fieldName: 'protected_branch[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedBranchCreate.getProtectedBranches,
    });

    this.loadPreviousSelection($allowedToMergeDropdown.data('glDropdown'), $allowedToPushDropdown.data('glDropdown'));
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $branchInput = this.$form.find('input[name="protected_branch[name]"]');
    const $allowedToMergeInput = this.$form.find('input[name="protected_branch[merge_access_levels_attributes][0][access_level]"]');
    const $allowedToPushInput = this.$form.find('input[name="protected_branch[push_access_levels_attributes][0][access_level]"]');
    const completedForm = !(
      $branchInput.val() &&
      $allowedToMergeInput.length &&
      $allowedToPushInput.length
    );

    this.savePreviousSelection($allowedToMergeInput.val(), $allowedToPushInput.val());
    this.$form.find('input[type="submit"]').prop('disabled', completedForm);
  }

  static getProtectedBranches(term, callback) {
    callback(gon.open_branches);
  }

  loadPreviousSelection(mergeDropdown, pushDropdown) {
    let mergeIndex = 0;
    let pushIndex = 0;
    if (this.isLocalStorageAvailable) {
      const savedDefaults = JSON.parse(window.localStorage.getItem(PB_LOCAL_STORAGE_KEY));
      if (savedDefaults != null) {
        mergeIndex = _.findLastIndex(mergeDropdown.fullData.roles, {
          id: parseInt(savedDefaults.mergeSelection, 0),
        });
        pushIndex = _.findLastIndex(pushDropdown.fullData.roles, {
          id: parseInt(savedDefaults.pushSelection, 0),
        });
      }
    }
    mergeDropdown.selectRowAtIndex(mergeIndex);
    pushDropdown.selectRowAtIndex(pushIndex);
  }

  savePreviousSelection(mergeSelection, pushSelection) {
    if (this.isLocalStorageAvailable) {
      const branchDefaults = {
        mergeSelection,
        pushSelection,
      };
      window.localStorage.setItem(PB_LOCAL_STORAGE_KEY, JSON.stringify(branchDefaults));
    }
  }
}
