export default class CILintEditor {
  constructor() {
    this.editor = window.ace.edit('ci-editor');
    this.textarea = document.querySelector('#content');
    this.clearYml = document.querySelector('.clear-yml');

    this.editor.getSession().setMode('ace/mode/yaml');
    this.editor.on('input', () => {
      const content = this.editor.getSession().getValue();
      this.textarea.value = content;
    });

    this.clearYml.addEventListener('click', this.clear.bind(this));
  }

  clear() {
    this.editor.setValue('');
  }
}
