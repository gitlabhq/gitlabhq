import $ from 'jquery';
import IssuableTemplateSelector from './issuable_template_selector';

export default class IssuableTemplateSelectors {
  constructor({ $dropdowns, editor, warnTemplateOverride } = {}) {
    this.$dropdowns = $dropdowns || $('.js-issuable-selector');
    this.editor = editor || this.initEditor();

    this.$dropdowns.each((i, dropdown) => {
      const $dropdown = $(dropdown);

      // eslint-disable-next-line no-new
      new IssuableTemplateSelector({
        pattern: /(\.md)/,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-issuable-selector-wrap'),
        dropdown: $dropdown,
        editor: this.editor,
        warnTemplateOverride,
      });
    });
  }

  // eslint-disable-next-line class-methods-use-this
  initEditor() {
    const editor = $('.markdown-area');
    // Proxy ace-editor's .setValue to jQuery's .val
    editor.setValue = editor.val;
    editor.getValue = editor.val;
    return editor;
  }
}
