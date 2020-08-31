import { editor as monacoEditor, languages as monacoLanguages, Uri } from 'monaco-editor';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import languages from '~/ide/lib/languages';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import { registerLanguages } from '~/ide/utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { clearDomElement } from './utils';
import { EDITOR_LITE_INSTANCE_ERROR_NO_EL, URI_PREFIX } from './constants';

export default class Editor {
  constructor(options = {}) {
    this.editorEl = null;
    this.blobContent = '';
    this.blobPath = '';
    this.instances = [];
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
  createInstance({
    el = undefined,
    blobPath = '',
    blobContent = '',
    blobGlobalId = '',
    ...instanceOptions
  } = {}) {
    if (!el) {
      throw new Error(EDITOR_LITE_INSTANCE_ERROR_NO_EL);
    }
    this.editorEl = el;
    this.blobContent = blobContent;
    this.blobPath = blobPath;

    clearDomElement(this.editorEl);

    const uriFilePath = joinPaths(URI_PREFIX, blobGlobalId, blobPath);

    const model = monacoEditor.createModel(this.blobContent, undefined, Uri.file(uriFilePath));

    monacoEditor.onDidCreateEditor(this.renderEditor.bind(this));

    const instance = monacoEditor.create(this.editorEl, {
      ...this.options,
      ...instanceOptions,
    });
    instance.setModel(model);
    instance.onDidDispose(() => {
      const index = this.instances.findIndex(inst => inst === instance);
      this.instances.splice(index, 1);
      model.dispose();
    });
    instance.updateModelLanguage = path => this.updateModelLanguage(path);

    // Reference to the model on the editor level will go away in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/241023
    // After that, the references to the model will be routed through
    // instance exclusively
    this.model = model;

    this.instances.push(instance);
    return instance;
  }

  dispose() {
    this.instances.forEach(instance => instance.dispose());
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

  use(exts = [], instance = null) {
    const extensions = Array.isArray(exts) ? exts : [exts];
    if (instance) {
      Object.assign(instance, ...extensions);
    } else {
      this.instances.forEach(inst => Object.assign(inst, ...extensions));
    }
  }
}
