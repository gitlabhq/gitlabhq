import BlobLicenseSelector from './blob_license_selector';

export default class BlobLicenseSelectors {
  constructor({ editor, $dropdowns } = {}) {
    this.editor = editor;
    this.$dropdowns = $dropdowns || $('.js-license-selector');
    this.initSelectors();
  }

  initSelectors() {
    const editor = this.editor;
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
