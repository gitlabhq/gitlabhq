import BlobGitignoreSelector from './blob_gitignore_selector';

export default class BlobGitignoreSelectors {
  constructor({ editor, $dropdowns } = {}) {
    this.editor = editor;
    this.$dropdowns = $dropdowns || $('.js-gitignore-selector');
    this.initSelectors();
  }

  initSelectors() {
    const editor = this.editor;
    this.$dropdowns.each((i, dropdown) => {
      const $dropdown = $(dropdown);
      return new BlobGitignoreSelector({
        editor,
        pattern: /(\.gitignore)/,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-gitignore-selector-wrap'),
        dropdown: $dropdown,
      });
    });
  }
}
