import $ from 'jquery';
import ProtectedTagAccessDropdown from './protected_tag_access_dropdown';
import CreateItemDropdown from '../create_item_dropdown';

export default class ProtectedTagCreate {
  constructor() {
    this.$form = $('.js-new-protected-tag');
    this.buildDropdowns();
  }

  buildDropdowns() {
    const $allowedToCreateDropdown = this.$form.find('.js-allowed-to-create');

    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Create dropdown
    this.protectedTagAccessDropdown = new ProtectedTagAccessDropdown({
      $dropdown: $allowedToCreateDropdown,
      data: gon.create_access_levels,
      onSelect: this.onSelectCallback,
    });

    // Select default
    $allowedToCreateDropdown.data('glDropdown').selectRowAtIndex(0);

    // Protected tag dropdown
    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: this.$form.find('.js-protected-tag-select'),
      defaultToggleLabel: 'Protected Tag',
      fieldName: 'protected_tag[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedTagCreate.getProtectedTags,
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $tagInput = this.$form.find('input[name="protected_tag[name]"]');
    const $allowedToCreateInput = this.$form.find('#create_access_levels_attributes');

    this.$form.find('input[type="submit"]').prop('disabled', !($tagInput.val() && $allowedToCreateInput.length));
  }

  static getProtectedTags(term, callback) {
    callback(gon.open_tags);
  }
}
