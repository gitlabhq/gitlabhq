import { editor as monacoEditor, languages as monacoLanguages, Uri } from 'monaco-editor';
import gitlabTheme from '~/ide/lib/themes/gl_theme';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import { clearDomElement } from './utils';

export default class Editor {
  constructor(options = {}) {
    this.editorEl = null;
    this.blobContent = '';
    this.blobPath = '';
    this.instance = null;
    this.model = null;
    this.options = {
      ...defaultEditorOptions,
      ...options,
    };

    Editor.setupMonacoTheme();
  }

  static setupMonacoTheme() {
    monacoEditor.defineTheme(gitlabTheme.themeName, gitlabTheme.monacoTheme);
    monacoEditor.setTheme('gitlab');
  }

  createInstance({ el = undefined, blobPath = '', blobContent = '' } = {}) {
    if (!el) return;
    this.editorEl = el;
    this.blobContent = blobContent;
    this.blobPath = blobPath;

    clearDomElement(this.editorEl);

    this.model = monacoEditor.createModel(
      this.blobContent,
      undefined,
      new Uri('gitlab', false, this.blobPath),
    );

    monacoEditor.onDidCreateEditor(this.renderEditor.bind(this));

    this.instance = monacoEditor.create(this.editorEl, this.options);
    this.instance.setModel(this.model);
  }

  dispose() {
    return this.instance && this.instance.dispose();
  }

  renderEditor() {
    delete this.editorEl.dataset.editorLoading;
  }

  updateModelLanguage(path) {
    if (path === this.blobPath) return;
    this.blobPath = path;
    const ext = `.${path.split('.').pop()}`;
    const language = monacoLanguages
      .getLanguages()
      .find(lang => lang.extensions.indexOf(ext) !== -1);
    const id = language ? language.id : 'plaintext';
    monacoEditor.setModelLanguage(this.model, id);
  }

  getValue() {
    return this.model.getValue();
  }
}
