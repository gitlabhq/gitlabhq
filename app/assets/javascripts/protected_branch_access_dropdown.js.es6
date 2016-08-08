(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchAccessDropdown = class {
    constructor(options) {
      const { $dropdown, data, onSelect } = options;

      $dropdown.glDropdown({
        data: data,
        selectable: true,
        inputId: $dropdown.data('input-id'),
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

})(window);
