(() => {
  const global = window.gl || (window.gl = {});

  class BlobDockerfileSelectors {
    constructor({ editor, $dropdowns } = {}) {
      this.editor = editor;
      this.$dropdowns = $dropdowns || $('.js-dockerfile-selector');
      this.initSelectors();
    }

    initSelectors() {
      const editor = this.editor;
      this.$dropdowns.each((i, dropdown) => {
        const $dropdown = $(dropdown);
        return new gl.BlobDockerfileSelector({
          editor,
          pattern: /(Dockerfile)/,
          data: $dropdown.data('data'),
          wrapper: $dropdown.closest('.js-dockerfile-selector-wrap'),
          dropdown: $dropdown,
        });
      });
    }
  }

  global.BlobDockerfileSelectors = BlobDockerfileSelectors;
})();
