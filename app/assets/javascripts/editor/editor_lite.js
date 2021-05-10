import { editor as monacoEditor, languages as monacoLanguages, Uri } from 'monaco-editor';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import languages from '~/ide/lib/languages';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import { registerLanguages } from '~/ide/utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { uuids } from '~/lib/utils/uuids';
import {
  EDITOR_LITE_INSTANCE_ERROR_NO_EL,
  URI_PREFIX,
  EDITOR_READY_EVENT,
  EDITOR_TYPE_DIFF,
} from './constants';
import { clearDomElement } from './utils';

export default class EditorLite {
  constructor(options = {}) {
    this.instances = [];
    this.options = {
      extraEditorClassName: 'gl-editor-lite',
      ...defaultEditorOptions,
      ...options,
    };

    EditorLite.setupMonacoTheme();

    registerLanguages(...languages);
  }

  static setupMonacoTheme() {
    const themeName = window.gon?.user_color_scheme || DEFAULT_THEME;
    const theme = themes.find((t) => t.name === themeName);
    if (theme) monacoEditor.defineTheme(themeName, theme.data);
    monacoEditor.setTheme(theme ? themeName : DEFAULT_THEME);
  }

  static getModelLanguage(path) {
    const ext = `.${path.split('.').pop()}`;
    const language = monacoLanguages
      .getLanguages()
      .find((lang) => lang.extensions.indexOf(ext) !== -1);
    return language ? language.id : 'plaintext';
  }

  static pushToImportsArray(arr, toImport) {
    arr.push(import(toImport));
  }

  static loadExtensions(extensions) {
    if (!extensions) {
      return Promise.resolve();
    }
    const promises = [];
    const extensionsArray = typeof extensions === 'string' ? extensions.split(',') : extensions;

    extensionsArray.forEach((ext) => {
      const prefix = ext.includes('/') ? '' : 'editor/';
      const trimmedExt = ext.replace(/^\//, '').trim();
      EditorLite.pushToImportsArray(promises, `~/${prefix}${trimmedExt}`);
    });

    return Promise.all(promises);
  }

  static mixIntoInstance(source, inst) {
    if (!inst) {
      return;
    }
    const isClassInstance = source.constructor.prototype !== Object.prototype;
    const sanitizedSource = isClassInstance ? source.constructor.prototype : source;
    Object.getOwnPropertyNames(sanitizedSource).forEach((prop) => {
      if (prop !== 'constructor') {
        Object.assign(inst, { [prop]: source[prop] });
      }
    });
  }

  static prepareInstance(el) {
    if (!el) {
      throw new Error(EDITOR_LITE_INSTANCE_ERROR_NO_EL);
    }

    clearDomElement(el);

    monacoEditor.onDidCreateEditor(() => {
      delete el.dataset.editorLoading;
    });
  }

  static manageDefaultExtensions(instance, el, extensions) {
    EditorLite.loadExtensions(extensions, instance)
      .then((modules) => {
        if (modules) {
          modules.forEach((module) => {
            instance.use(module.default);
          });
        }
      })
      .then(() => {
        el.dispatchEvent(new Event(EDITOR_READY_EVENT));
      })
      .catch((e) => {
        throw e;
      });
  }

  static createEditorModel({
    blobPath,
    blobContent,
    blobOriginalContent,
    blobGlobalId,
    instance,
    isDiff,
  } = {}) {
    if (!instance) {
      return null;
    }
    const uriFilePath = joinPaths(URI_PREFIX, blobGlobalId, blobPath);
    const uri = Uri.file(uriFilePath);
    const existingModel = monacoEditor.getModel(uri);
    const model = existingModel || monacoEditor.createModel(blobContent, undefined, uri);
    if (!isDiff) {
      instance.setModel(model);
      return model;
    }
    const diffModel = {
      original: monacoEditor.createModel(
        blobOriginalContent,
        EditorLite.getModelLanguage(model.uri.path),
      ),
      modified: model,
    };
    instance.setModel(diffModel);
    return diffModel;
  }

  static convertMonacoToELInstance = (inst) => {
    const editorLiteInstanceAPI = {
      updateModelLanguage: (path) => {
        return EditorLite.instanceUpdateLanguage(inst, path);
      },
      use: (exts = []) => {
        return EditorLite.instanceApplyExtension(inst, exts);
      },
    };
    const handler = {
      get(target, prop, receiver) {
        if (Reflect.has(editorLiteInstanceAPI, prop)) {
          return editorLiteInstanceAPI[prop];
        }
        return Reflect.get(target, prop, receiver);
      },
    };
    return new Proxy(inst, handler);
  };

  static instanceUpdateLanguage(inst, path) {
    const lang = EditorLite.getModelLanguage(path);
    const model = inst.getModel();
    return monacoEditor.setModelLanguage(model, lang);
  }

  static instanceApplyExtension(inst, exts = []) {
    const extensions = [].concat(exts);
    extensions.forEach((extension) => {
      EditorLite.mixIntoInstance(extension, inst);
    });
    return inst;
  }

  static instanceRemoveFromRegistry(editor, instance) {
    const index = editor.instances.findIndex((inst) => inst === instance);
    editor.instances.splice(index, 1);
  }

  static instanceDisposeModels(editor, instance, model) {
    const instanceModel = instance.getModel() || model;
    if (!instanceModel) {
      return;
    }
    if (instance.getEditorType() === EDITOR_TYPE_DIFF) {
      const { original, modified } = instanceModel;
      if (original) {
        original.dispose();
      }
      if (modified) {
        modified.dispose();
      }
    } else {
      instanceModel.dispose();
    }
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
    blobOriginalContent = '',
    blobGlobalId = uuids()[0],
    extensions = [],
    isDiff = false,
    ...instanceOptions
  } = {}) {
    EditorLite.prepareInstance(el);

    const createEditorFn = isDiff ? 'createDiffEditor' : 'create';
    const instance = EditorLite.convertMonacoToELInstance(
      monacoEditor[createEditorFn].call(this, el, {
        ...this.options,
        ...instanceOptions,
      }),
    );

    let model;
    if (instanceOptions.model !== null) {
      model = EditorLite.createEditorModel({
        blobGlobalId,
        blobOriginalContent,
        blobPath,
        blobContent,
        instance,
        isDiff,
      });
    }

    instance.onDidDispose(() => {
      EditorLite.instanceRemoveFromRegistry(this, instance);
      EditorLite.instanceDisposeModels(this, instance, model);
    });

    EditorLite.manageDefaultExtensions(instance, el, extensions);

    this.instances.push(instance);
    return instance;
  }

  createDiffInstance(args) {
    return this.createInstance({
      ...args,
      isDiff: true,
    });
  }

  dispose() {
    this.instances.forEach((instance) => instance.dispose());
  }

  use(exts) {
    this.instances.forEach((inst) => {
      inst.use(exts);
    });
    return this;
  }
}
