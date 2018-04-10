export default class ProtectedTagAccessDropdown {
  constructor(options) {
    this.options = options;
    this.initDropdown();
  }

  initDropdown() {
    const { onSelect } = this.options;
    this.options.$dropdown.glDropdown({
      data: this.options.data,
      selectable: true,
      inputId: this.options.$dropdown.data('inputId'),
      fieldName: this.options.$dropdown.data('fieldName'),
      toggleLabel(item, $el) {
        if ($el.is('.is-active')) {
          return item.text;
        }
        return 'Select';
      },
      clicked(options) {
        options.e.preventDefault();
        onSelect();
      },
    });
  }
}
