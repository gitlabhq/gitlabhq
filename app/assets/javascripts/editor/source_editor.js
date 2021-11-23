import { editor as monacoEditor, Uri } from 'monaco-editor';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import languages from '~/ide/lib/languages';
import { registerLanguages } from '~/ide/utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { uuids } from '~/lib/utils/uuids';
import {
  SOURCE_EDITOR_INSTANCE_ERROR_NO_EL,
  URI_PREFIX,
  EDITOR_READY_EVENT,
  EDITOR_TYPE_DIFF,
} from './constants';
import { clearDomElement, setupEditorTheme, getBlobLanguage } from './utils';

export default class SourceEditor {
  constructor(options = {}) {
    this.instances = [];
    this.options = {
      extraEditorClassName: 'gl-source-editor',
      ...defaultEditorOptions,
      ...options,
    };

    setupEditorTheme();

    registerLanguages(...languages);
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
      throw new Error(SOURCE_EDITOR_INSTANCE_ERROR_NO_EL);
    }

    clearDomElement(el);

    monacoEditor.onDidCreateEditor(() => {
      delete el.dataset.editorLoading;
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
      original: monacoEditor.createModel(blobOriginalContent, getBlobLanguage(model.uri.path)),
      modified: model,
    };
    instance.setModel(diffModel);
    return diffModel;
  }

  static convertMonacoToELInstance = (inst) => {
    const sourceEditorInstanceAPI = {
      updateModelLanguage: (path) => {
        return SourceEditor.instanceUpdateLanguage(inst, path);
      },
      use: (exts = []) => {
        return SourceEditor.instanceApplyExtension(inst, exts);
      },
    };
    const handler = {
      get(target, prop, receiver) {
        if (Reflect.has(sourceEditorInstanceAPI, prop)) {
          return sourceEditorInstanceAPI[prop];
        }
        return Reflect.get(target, prop, receiver);
      },
    };
    return new Proxy(inst, handler);
  };

  static instanceUpdateLanguage(inst, path) {
    const lang = getBlobLanguage(path);
    const model = inst.getModel();
    return monacoEditor.setModelLanguage(model, lang);
  }

  static instanceApplyExtension(inst, exts = []) {
    const extensions = [].concat(exts);
    extensions.forEach((extension) => {
      SourceEditor.mixIntoInstance(extension, inst);
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
    isDiff = false,
    ...instanceOptions
  } = {}) {
    SourceEditor.prepareInstance(el);

    const createEditorFn = isDiff ? 'createDiffEditor' : 'create';
    const instance = SourceEditor.convertMonacoToELInstance(
      monacoEditor[createEditorFn].call(this, el, {
        ...this.options,
        ...instanceOptions,
      }),
    );

    let model;
    if (instanceOptions.model !== null) {
      model = SourceEditor.createEditorModel({
        blobGlobalId,
        blobOriginalContent,
        blobPath,
        blobContent,
        instance,
        isDiff,
      });
    }

    instance.onDidDispose(() => {
      SourceEditor.instanceRemoveFromRegistry(this, instance);
      SourceEditor.instanceDisposeModels(this, instance, model);
    });

    this.instances.push(instance);
    el.dispatchEvent(new CustomEvent(EDITOR_READY_EVENT, { instance }));
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
}
