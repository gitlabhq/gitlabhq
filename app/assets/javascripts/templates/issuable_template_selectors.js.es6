((global) => {
  class IssuableTemplateSelectors {
    constructor(opts = {}) {
      this.$dropdowns = opts.$dropdowns || $('.js-issuable-selector');
      this.editor = opts.editor || this.initEditor();

      this.$dropdowns.each((i, dropdown) => {
        let $dropdown = $(dropdown);
        new IssuableTemplateSelector({
          pattern: /(\.md)/,
          data: $dropdown.data('data'),
          wrapper: $dropdown.closest('.js-issuable-selector-wrap'),
          dropdown: $dropdown,
          editor: this.editor
        });
      });
    }

    initEditor() {
      let editor = $('.markdown-area');
      // Proxy ace-editor's .setValue to jQuery's .val
      editor.setValue = editor.val;
      editor.getValue = editor.val;
      return editor;
    }
  }

  global.Dispatcher.register([
    'projects:issues:new',
    'projects:issues:edit',
    'projects:merge_requests:new',
    'projects:merge_requests:edit'
  ], IssuableTemplateSelectors);

})(window.gl || (window.gl = {}));
