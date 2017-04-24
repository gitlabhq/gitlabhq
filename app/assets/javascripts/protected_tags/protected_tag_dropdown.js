import { ProtectedRefDropdown } from '../protected_refs';

export default class ProtectedTagDropdown extends ProtectedRefDropdown {
  /**
   * @param {Object} options matching ProtectedRefDropdown's constructor.
   */
  constructor(options) {
    const $dropdownContainer = options.$dropdown.parent();

    super(options, {
      $dropdownFooter: $dropdownContainer.find('.dropdown-footer'),
      $createNewProtectedRef: $dropdownContainer.find('.js-create-new-protected-tag'),
      protectedRefFieldName: 'protected_tag[name]',
      dropdownLabel: 'Protected Tag',
      protectedRefsList: gon.open_tags,
    });
  }
}
