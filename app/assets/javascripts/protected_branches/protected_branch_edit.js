import flash from '../flash';
import axios from '../lib/utils/axios_utils';
import ProtectedBranchAccessDropdown from './protected_branch_access_dropdown';

export default class ProtectedBranchEdit {
  constructor(options) {
    this.$wrap = options.$wrap;
    this.$allowedToMergeDropdown = this.$wrap.find('.js-allowed-to-merge');
    this.$allowedToPushDropdown = this.$wrap.find('.js-allowed-to-push');
    this.onSelectCallback = this.onSelect.bind(this);

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to merge dropdown
    this.protectedBranchAccessDropdown = new ProtectedBranchAccessDropdown({
      $dropdown: this.$allowedToMergeDropdown,
      data: gon.merge_access_levels,
      onSelect: this.onSelectCallback,
    });

    // Allowed to push dropdown
    this.protectedBranchAccessDropdown = new ProtectedBranchAccessDropdown({
      $dropdown: this.$allowedToPushDropdown,
      data: gon.push_access_levels,
      onSelect: this.onSelectCallback,
    });
  }

  onSelect() {
    const $allowedToMergeInput = this.$wrap.find(`input[name="${this.$allowedToMergeDropdown.data('fieldName')}"]`);
    const $allowedToPushInput = this.$wrap.find(`input[name="${this.$allowedToPushDropdown.data('fieldName')}"]`);

    // Do not update if one dropdown has not selected any option
    if (!($allowedToMergeInput.length && $allowedToPushInput.length)) return;

    this.$allowedToMergeDropdown.disable();
    this.$allowedToPushDropdown.disable();

    axios.patch(this.$wrap.data('url'), {
      protected_branch: {
        merge_access_levels_attributes: [{
          id: this.$allowedToMergeDropdown.data('accessLevelId'),
          access_level: $allowedToMergeInput.val(),
        }],
        push_access_levels_attributes: [{
          id: this.$allowedToPushDropdown.data('accessLevelId'),
          access_level: $allowedToPushInput.val(),
        }],
      },
    }).then(() => {
      this.$allowedToMergeDropdown.enable();
      this.$allowedToPushDropdown.enable();
    }).catch(() => {
      this.$allowedToMergeDropdown.enable();
      this.$allowedToPushDropdown.enable();

      flash('Failed to update branch!', 'alert', document.querySelector('.js-protected-branches-list'));
    });
  }
}
