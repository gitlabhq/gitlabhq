export default class ProtectedRefAccessDropdown {
  constructor(options, { inputId, fieldName, activeCls }) {
    this.options = options;
    this.inputId = inputId;
    this.fieldName = fieldName;
    this.activeCls = activeCls;
    this.initDropdown();
  }

  initDropdown() {
    const { onSelect } = this.options;
    const activeCls = this.activeCls;
    this.options.$dropdown.glDropdown({
      data: this.options.data,
      selectable: true,
      inputId: this.options.$dropdown.data(this.inputId),
      fieldName: this.options.$dropdown.data(this.fieldName),
      toggleLabel(item, $el) {
        if ($el.is(activeCls)) {
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
