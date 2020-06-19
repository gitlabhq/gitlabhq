import { editor as monacoEditor, languages as monacoLanguages, Position, Uri } from 'monaco-editor';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import languages from '~/ide/lib/languages';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import { registerLanguages } from '~/ide/utils';
import { clearDomElement } from './utils';

export default class Editor {
  constructor(options = {}) {
    this.editorEl = null;
    this.blobContent = '';
    this.blobPath = '';
    this.instance = null;
    this.model = null;
    this.options = {
      extraEditorClassName: 'gl-editor-lite',
      ...defaultEditorOptions,
      ...options,
    };

    Editor.setupMonacoTheme();

    registerLanguages(...languages);
  }

  static setupMonacoTheme() {
    const themeName = window.gon?.user_color_scheme || DEFAULT_THEME;
    const theme = themes.find(t => t.name === themeName);
    if (theme) monacoEditor.defineTheme(themeName, theme.data);
    monacoEditor.setTheme(theme ? themeName : DEFAULT_THEME);
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
    return this.instance.getValue();
  }

  setValue(val) {
    this.instance.setValue(val);
  }

  focus() {
    this.instance.focus();
  }

  navigateFileStart() {
    this.instance.setPosition(new Position(1, 1));
  }

  updateOptions(options = {}) {
    this.instance.updateOptions(options);
  }
}
