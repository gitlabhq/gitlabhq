((global) => {
  class BlobLicenseSelectors {
    constructor({ $dropdowns, editor }) {
      this.$dropdowns = $('.js-license-selector');
      this.editor = editor;
      this.$dropdowns.each((dropdown) => {
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

  global.BlobLicenseSelectors = BlobLicenseSelectors;

})(window.gl || (window.gl = {}));
