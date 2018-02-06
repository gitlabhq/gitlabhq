export default class CILintEditor {
  constructor() {
    this.editor = window.ace.edit('ci-editor');
    this.textarea = document.querySelector('#content');

    this.editor.getSession().setMode('ace/mode/yaml');
    this.editor.on('input', () => {
      const content = this.editor.getSession().getValue();
      this.textarea.value = content;
    });
  }
}
