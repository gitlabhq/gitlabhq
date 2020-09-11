import createFlash from '~/flash';
import { BLOB_EDITOR_ERROR } from '~/blob_edit/constants';

export default class CILintEditor {
  constructor() {
    const monacoEnabled = window?.gon?.features?.monacoCi;
    this.clearYml = document.querySelector('.clear-yml');
    this.clearYml.addEventListener('click', this.clear.bind(this));

    return monacoEnabled ? this.initEditorLite() : this.initAce();
  }

  clear() {
    this.editor.setValue('');
  }

  initEditorLite() {
    import(/* webpackChunkName: 'monaco_editor_lite' */ '~/editor/editor_lite')
      .then(({ default: EditorLite }) => {
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
      })
      .catch(() => createFlash({ message: BLOB_EDITOR_ERROR }));
  }

  initAce() {
    this.editor = window.ace.edit('ci-editor');
    this.textarea = document.getElementById('content');

    this.editor.getSession().setMode('ace/mode/yaml');
    this.editor.on('input', () => {
      this.textarea.value = this.editor.getSession().getValue();
    });
  }
}
