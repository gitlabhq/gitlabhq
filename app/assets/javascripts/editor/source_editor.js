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
import EditorInstance from './source_editor_instance';

const instanceRemoveFromRegistry = (editor, instance) => {
  const index = editor.instances.findIndex((inst) => inst === instance);
  editor.instances.splice(index, 1);
};

const instanceDisposeModels = (editor, instance, model) => {
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
};

export default class SourceEditor {
  /**
   * Constructs a global editor.
   * @param {Object} options - Monaco config options used to create the editor
   */
  constructor(options = {}) {
    this.instances = [];
    this.extensionsStore = new Map();
    this.options = {
      extraEditorClassName: 'gl-source-editor',
      ...defaultEditorOptions,
      ...options,
    };

    setupEditorTheme();

    registerLanguages(...languages);
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
    language,
  } = {}) {
    if (!instance) {
      return null;
    }
    const uriFilePath = joinPaths(URI_PREFIX, blobGlobalId, blobPath);
    const uri = Uri.file(uriFilePath);
    const existingModel = monacoEditor.getModel(uri);
    const model = existingModel || monacoEditor.createModel(blobContent, language, uri);
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

  /**
   * Creates a Source Editor Instance with the given options.
   * @param {Object} options Options used to initialize the instance.
   * @param {Element} options.el The element to attach the instance for.
   * @param {string} options.blobPath The path used as the URI of the model. Monaco uses the extension of this path to determine the language.
   * @param {string} options.blobContent The content to initialize the monacoEditor.
   * @param {string} options.blobOriginalContent The original blob's content. Is used when creating a Diff Instance.
   * @param {string} options.blobGlobalId This is used to help globally identify monaco instances that are created with the same blobPath.
   * @param {Boolean} options.isDiff Flag to enable creation of a Diff Instance?
   * @param {...*} options.instanceOptions Configuration options used to instantiate an instance.
   * @returns {EditorInstance}
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
    const instance = new EditorInstance(
      monacoEditor[createEditorFn].call(this, el, {
        ...this.options,
        ...instanceOptions,
      }),
      this.extensionsStore,
    );

    instance.layout();

    let model;
    const language = instanceOptions.language || getBlobLanguage(blobPath);
    if (instanceOptions.model !== null) {
      model = SourceEditor.createEditorModel({
        blobGlobalId,
        blobOriginalContent,
        blobPath,
        blobContent,
        instance,
        isDiff,
        language,
      });
    }

    instance.onDidDispose(() => {
      instanceRemoveFromRegistry(this, instance);
      instanceDisposeModels(this, instance, model);
    });

    this.instances.push(instance);
    el.dispatchEvent(new CustomEvent(EDITOR_READY_EVENT, { detail: { instance } }));
    return instance;
  }

  /**
   * Create a Diff Instance
   * @param {Object} args Options to be passed further down to createInstance() with the same signature
   * @returns {EditorInstance}
   */
  createDiffInstance(args) {
    return this.createInstance({
      ...args,
      isDiff: true,
    });
  }

  /**
   * Dispose global editor
   * Automatically disposes all the instances registered for this editor
   */
  dispose() {
    this.instances.forEach((instance) => instance.dispose());
  }
}
