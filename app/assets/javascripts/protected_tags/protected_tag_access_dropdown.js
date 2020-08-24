import { __ } from '~/locale';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default class ProtectedTagAccessDropdown {
  constructor(options) {
    this.options = options;
    this.initDropdown();
  }

  initDropdown() {
    const { onSelect } = this.options;
    initDeprecatedJQueryDropdown(this.options.$dropdown, {
      data: this.options.data,
      selectable: true,
      inputId: this.options.$dropdown.data('inputId'),
      fieldName: this.options.$dropdown.data('fieldName'),
      toggleLabel(item, $el) {
        if ($el.is('.is-active')) {
          return item.text;
        }
        return __('Select');
      },
      clicked(options) {
        options.e.preventDefault();
        onSelect();
      },
    });
  }
}
