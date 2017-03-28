import BlobDockerfileSelector from './blob_dockerfile_selector';

export default class BlobDockerfileSelectors {
  constructor({ editor, $dropdowns }) {
    this.editor = editor;
    this.$dropdowns = $dropdowns || $('.js-dockerfile-selector');
    this.initSelectors();
  }

  initSelectors() {
    const editor = this.editor;
    this.$dropdowns.each((i, dropdown) => {
      const $dropdown = $(dropdown);
      return new BlobDockerfileSelector({
        editor,
        pattern: /(Dockerfile)/,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-dockerfile-selector-wrap'),
        dropdown: $dropdown,
      });
    });
  }
}
