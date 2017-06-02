let instanceCount = 0;

class AutoWidthDropdownSelect {
  constructor(selectElement) {
    this.$selectElement = $(selectElement);
    this.dropdownClass = `js-auto-width-select-dropdown-${instanceCount}`;
    instanceCount += 1;
  }

  init() {
    const dropdownClass = this.dropdownClass;
    this.$selectElement.select2({
      dropdownCssClass: dropdownClass,
      dropdownCss() {
        let resultantWidth = 'auto';
        const $dropdown = $(`.${dropdownClass}`);

        // We have to look at the parent because
        // `offsetParent` on a `display: none;` is `null`
        const offsetParentWidth = $(this).parent().offsetParent().width();
        // Reset any width to let it naturally flow
        $dropdown.css('width', 'auto');
        if ($dropdown.outerWidth(false) > offsetParentWidth) {
          resultantWidth = offsetParentWidth;
        }

        return {
          width: resultantWidth,
          maxWidth: offsetParentWidth,
        };
      },
    });

    return this;
  }
}

export default AutoWidthDropdownSelect;
