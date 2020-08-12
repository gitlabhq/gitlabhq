import { editor as monacoEditor, languages as monacoLanguages, Position, Uri } from 'monaco-editor';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import languages from '~/ide/lib/languages';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import { registerLanguages } from '~/ide/utils';
import { joinPaths } from '~/lib/utils/url_utility';
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

  /**
   * Creates a monaco instance with the given options.
   *
   * @param {Object} options Options used to initialize monaco.
   * @param {Element} options.el The element which will be used to create the monacoEditor.
   * @param {string} options.blobPath The path used as the URI of the model. Monaco uses the extension of this path to determine the language.
   * @param {string} options.blobContent The content to initialize the monacoEditor.
   * @param {string} options.blobGlobalId This is used to help globally identify monaco instances that are created with the same blobPath.
   */
  createInstance({ el = undefined, blobPath = '', blobContent = '', blobGlobalId = '' } = {}) {
    if (!el) return;
    this.editorEl = el;
    this.blobContent = blobContent;
    this.blobPath = blobPath;

    clearDomElement(this.editorEl);

    const uriFilePath = joinPaths('gitlab', blobGlobalId, blobPath);

    this.model = monacoEditor.createModel(this.blobContent, undefined, Uri.file(uriFilePath));

    monacoEditor.onDidCreateEditor(this.renderEditor.bind(this));

    this.instance = monacoEditor.create(this.editorEl, this.options);
    this.instance.setModel(this.model);
  }

  dispose() {
    if (this.model) {
      this.model.dispose();
      this.model = null;
    }

    return this.instance && this.instance.dispose();
  }

  renderEditor() {
    delete this.editorEl.dataset.editorLoading;
  }

  onChangeContent(fn) {
    return this.model.onDidChangeContent(fn);
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

  use(exts = []) {
    const extensions = Array.isArray(exts) ? exts : [exts];
    Object.assign(this, ...extensions);
  }
}
