import ProtectedTagAccessDropdown from './protected_tag_access_dropdown';
import ProtectedTagDropdown from './protected_tag_dropdown';

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
    this.protectedTagDropdown = new ProtectedTagDropdown({
      $dropdown: this.$form.find('.js-protected-tag-select'),
      onSelect: this.onSelectCallback,
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $tagInput = this.$form.find('input[name="protected_tag[name]"]');
    const $allowedToCreateInput = this.$form.find('#create_access_levels_attributes');

    this.$form.find('input[type="submit"]').attr('disabled', !($tagInput.val() && $allowedToCreateInput.length));
  }
}
