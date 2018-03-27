export default class ProtectedBranchAccessDropdown {
  constructor(options) {
    this.options = options;
    this.initDropdown();
  }

  initDropdown() {
    const { $dropdown, data, onSelect } = this.options;
    $dropdown.glDropdown({
      data,
      selectable: true,
      inputId: $dropdown.data('inputId'),
      fieldName: $dropdown.data('fieldName'),
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
