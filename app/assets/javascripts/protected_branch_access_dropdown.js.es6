class ProtectedBranchAccessDropdown {
  constructor(options) {
    const { $dropdown, data, onSelect } = options;

    $dropdown.glDropdown({
      data: data,
      selectable: true,
      fieldName: $dropdown.data('field-name'),
      toggleLabel(item) {
        return item.text;
      },
      clicked(item, $el, e) {
        e.preventDefault();
        onSelect();
      }
    });
  }
}
