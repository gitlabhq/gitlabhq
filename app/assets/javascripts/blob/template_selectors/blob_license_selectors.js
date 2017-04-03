/* eslint-disable no-unused-vars, no-param-reassign */

import BlobLicenseSelector from './blob_license_selector';

export default class BlobLicenseSelectors {
  constructor({ $dropdowns, editor }) {
    this.$dropdowns = $dropdowns || $('.js-license-selector');
    this.initSelectors(editor);
  }

  initSelectors(editor) {
    this.$dropdowns.each((i, dropdown) => {
      const $dropdown = $(dropdown);

      return new BlobLicenseSelector({
        editor,
        pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-license-selector-wrap'),
        dropdown: $dropdown,
      });
    });
  }
}
