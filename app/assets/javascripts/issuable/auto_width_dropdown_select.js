import $ from 'jquery';
import { loadCSSFile } from '../lib/utils/css_utils';

let instanceCount = 0;

class AutoWidthDropdownSelect {
  constructor(selectElement) {
    this.$selectElement = $(selectElement);
    this.dropdownClass = `js-auto-width-select-dropdown-${instanceCount}`;
    instanceCount += 1;
  }

  init() {
    const { dropdownClass } = this;
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        // eslint-disable-next-line promise/no-nesting
        loadCSSFile(gon.select2_css_path)
          .then(() => {
            this.$selectElement.select2({
              dropdownCssClass: dropdownClass,
              ...AutoWidthDropdownSelect.selectOptions(this.dropdownClass),
            });
          })
          .catch(() => {});
      })
      .catch(() => {});

    return this;
  }

  static selectOptions(dropdownClass) {
    return {
      dropdownCss() {
        let resultantWidth = 'auto';
        const $dropdown = $(`.${dropdownClass}`);

        // We have to look at the parent because
        // `offsetParent` on a `display: none;` is `null`
        const offsetParentWidth = $(this)
          .parent()
          .offsetParent()
          .width();
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
    };
  }
}

export default AutoWidthDropdownSelect;
