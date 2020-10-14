import EditorLite from '~/editor/editor_lite';

export default class CILintEditor {
  constructor() {
    this.clearYml = document.querySelector('.clear-yml');
    this.clearYml.addEventListener('click', this.clear.bind(this));

    return this.initEditorLite();
  }

  clear() {
    this.editor.setValue('');
  }

  initEditorLite() {
    const editorEl = document.getElementById('editor');
    const fileContentEl = document.getElementById('content');
    const form = document.querySelector('.js-ci-lint-form');

    const rootEditor = new EditorLite();

    this.editor = rootEditor.createInstance({
      el: editorEl,
      blobPath: '.gitlab-ci.yml',
      blobContent: editorEl.innerText,
    });

    form.addEventListener('submit', () => {
      fileContentEl.value = this.editor.getValue();
    });
  }
}
