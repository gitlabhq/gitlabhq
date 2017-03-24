import BlobGitignoreSelector from './blob_gitignore_selector';

export default class BlobGitignoreSelectors {
  constructor({ editor, $dropdowns }) {
    this.$dropdowns = $dropdowns || $('.js-gitignore-selector');
    this.editor = editor;
    this.initSelectors();
  }

  initSelectors() {
    this.$dropdowns.each((i, dropdown) => {
      const $dropdown = $(dropdown);

      return new BlobGitignoreSelector({
        pattern: /(.gitignore)/,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-gitignore-selector-wrap'),
        dropdown: $dropdown,
        editor: this.editor,
      });
    });
  }
}
