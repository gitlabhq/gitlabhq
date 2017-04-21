import { ProtectedRefDropdown } from '../protected_refs';

export default class ProtectedBranchDropdown extends ProtectedRefDropdown {
  /**
   * @param {Object} options matching ProtectedRefDropdown's constructor.
   */
  constructor(options) {
    const $dropdownContainer = options.$dropdown.parent();

    super(options, {
      $dropdownFooter: $dropdownContainer.find('.dropdown-footer'),
      $createNewProtectedRef: $dropdownContainer.find('.js-create-new-protected-branch'),
      protectedRefFieldName: 'protected_branch[name]',
      dropdownLabel: 'Protected Branch',
      protectedRefsList: gon.open_branches,
    });
  }
}
