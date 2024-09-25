/**
 * @module source_editor_instance
 */

/**
 * A Source Editor Extension definition
 * @typedef {Object} SourceEditorExtensionDefinition
 * @property {Object} definition
 * @property {Object} setupOptions
 */

/**
 * A Source Editor Extension
 * @typedef {Object} SourceEditorExtension
 * @property {Object} obj
 * @property {string} extensionName
 * @property {Object} api
 */

import { isEqual } from 'lodash';
import { editor as monacoEditor } from 'monaco-editor';
import { enableMonacoYamlWorkerForVite, getBlobLanguage } from '~/editor/utils';
import { logError } from '~/lib/logger';
import { sprintf } from '~/locale';
import EditorExtension from './source_editor_extension';
import {
  EDITOR_EXTENSION_DEFINITION_TYPE_ERROR,
  EDITOR_EXTENSION_NAMING_CONFLICT_ERROR,
  EDITOR_EXTENSION_NO_DEFINITION_ERROR,
  EDITOR_EXTENSION_NOT_REGISTERED_ERROR,
  EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR,
  EDITOR_EXTENSION_STORE_IS_MISSING_ERROR,
} from './constants';

const utils = {
  removeExtFromMethod: (method, extensionName, container) => {
    if (!container) {
      return;
    }
    if (Object.prototype.hasOwnProperty.call(container, method)) {
      // eslint-disable-next-line no-param-reassign
      delete container[method];
    }
  },

  getStoredExtension: (extensionsStore, extensionName) => {
    if (!extensionsStore) {
      logError(EDITOR_EXTENSION_STORE_IS_MISSING_ERROR);
      return undefined;
    }
    return extensionsStore.get(extensionName);
  },

  hasFullApiRegistered: (targetMethods, newMethods) => {
    return newMethods.find((fn) => !targetMethods.includes(fn)) === undefined;
  },
};

/** Class representing a Source Editor Instance */
export default class EditorInstance {
  /**
   * Create a Source Editor Instance
   * @param {Object} rootInstance - Monaco instance to build on top of
   * @param {Map} extensionsStore - The global registry for the extension instances
   * @returns {Object} - A Proxy returning props/methods from either registered extensions, or Source Editor instance, or underlying Monaco instance
   */
  constructor(rootInstance = {}, extensionsStore = new Map()) {
    enableMonacoYamlWorkerForVite();

    /** The methods provided by extensions. */
    this.methods = {};

    const seInstance = this;
    const getHandler = {
      get(target, prop, receiver) {
        const methodExtension =
          Object.prototype.hasOwnProperty.call(seInstance.methods, prop) &&
          seInstance.methods[prop];
        if (methodExtension) {
          const extension = extensionsStore.get(methodExtension);

          if (typeof extension.api[prop] === 'function') {
            return extension.api[prop].bind(extension.obj, receiver);
          }

          return extension.api[prop];
        }
        return Reflect.get(seInstance[prop] ? seInstance : target, prop, receiver);
      },
    };
    const instProxy = new Proxy(rootInstance, getHandler);

    this.dispatchExtAction = EditorInstance.useUnuse.bind(instProxy, extensionsStore);

    // eslint-disable-next-line no-constructor-return
    return instProxy;
  }

  /**
   * A private dispatcher function for both `use` and `unuse`
   * @param {Map} extensionsStore - The global registry for the extension instances
   * @param {Function} fn - A function to route to. Either `this.useExtension` or `this.unuseExtension`
   * @param {SourceEditorExtensionDefinition[]} extensions - The extensions to use/unuse.
   * @returns {Function}
   */
  static useUnuse(extensionsStore, fn, extensions) {
    if (Array.isArray(extensions)) {
      /**
       * We cut short if the Array is empty and let the destination function to throw
       * Otherwise, we run the destination function on every entry of the Array
       */
      return extensions.length
        ? extensions.map(fn.bind(this, extensionsStore))
        : fn.call(this, extensionsStore);
    }
    return fn.call(this, extensionsStore, extensions);
  }

  //
  // REGISTERING NEW EXTENSION
  //

  /**
   * Run all registrations when using an extension
   * @param {Map} extensionsStore - The global registry for the extension instances
   * @param {SourceEditorExtensionDefinition} extension - The extension definition to use.
   * @returns {EditorExtension|*}
   */
  useExtension(extensionsStore, extension = {}) {
    const { definition } = extension;
    if (!definition) {
      throw new Error(EDITOR_EXTENSION_NO_DEFINITION_ERROR);
    }
    if (typeof definition !== 'function') {
      throw new Error(EDITOR_EXTENSION_DEFINITION_TYPE_ERROR);
    }

    // Existing Extension Path
    const existingExt = utils.getStoredExtension(extensionsStore, definition.extensionName);
    if (existingExt) {
      if (isEqual(extension.setupOptions, existingExt.setupOptions)) {
        if (utils.hasFullApiRegistered(this.extensionsAPI, Object.keys(existingExt.api))) {
          return existingExt;
        }
      }
      this.unuseExtension(extensionsStore, existingExt);
    }

    // New Extension Path
    const extensionInstance = new EditorExtension(extension);
    const { setupOptions, obj: extensionObj } = extensionInstance;
    if (extensionObj.onSetup) {
      extensionObj.onSetup(this, setupOptions);
    }
    if (extensionsStore) {
      this.registerExtension(extensionInstance, extensionsStore);
    }
    this.registerExtensionMethods(extensionInstance);
    return extensionInstance;
  }

  /**
   * Register extension in the global extensions store
   * @param {SourceEditorExtension} extension - Instance of Source Editor extension
   * @param {Map} extensionsStore - The global registry for the extension instances
   */
  registerExtension(extension, extensionsStore) {
    const { extensionName } = extension;
    const hasExtensionRegistered =
      extensionsStore.has(extensionName) &&
      isEqual(extension.setupOptions, extensionsStore.get(extensionName).setupOptions);
    if (hasExtensionRegistered) {
      return;
    }
    extensionsStore.set(extensionName, extension);
    const { obj: extensionObj } = extension;
    if (extensionObj.onUse) {
      extensionObj.onUse(this);
    }
  }

  /**
   * Register extension methods in the registry on the instance
   * @param {SourceEditorExtension} extension - Instance of Source Editor extension
   */
  registerExtensionMethods(extension) {
    const { api, extensionName } = extension;

    if (!api) {
      return;
    }

    Object.keys(api).forEach((prop) => {
      if (this[prop]) {
        logError(sprintf(EDITOR_EXTENSION_NAMING_CONFLICT_ERROR, { prop }));
      } else {
        this.methods[prop] = extensionName;
      }
    }, this);
  }

  //
  // UNREGISTERING AN EXTENSION
  //

  /**
   * Unregister extension with the cleanup
   * @param {Map} extensionsStore - The global registry for the extension instances
   * @param {SourceEditorExtension} extension - Instance of Source Editor extension to un-use
   */
  unuseExtension(extensionsStore, extension) {
    if (!extension) {
      throw new Error(EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR);
    }
    const { extensionName } = extension;
    const existingExt = utils.getStoredExtension(extensionsStore, extensionName);
    if (!existingExt) {
      throw new Error(sprintf(EDITOR_EXTENSION_NOT_REGISTERED_ERROR, { extensionName }));
    }
    const { obj: extensionObj } = existingExt;
    if (extensionObj.onBeforeUnuse) {
      extensionObj.onBeforeUnuse(this);
    }
    this.unregisterExtensionMethods(existingExt);
    if (extensionObj.onUnuse) {
      extensionObj.onUnuse(this);
    }
  }

  /**
   * Remove all methods associated with this extension from the registry on the instance
   * @param {SourceEditorExtension} extension - Instance of Source Editor extension to un-use
   */
  unregisterExtensionMethods(extension) {
    const { api, extensionName } = extension;
    if (!api) {
      return;
    }
    Object.keys(api).forEach((method) => {
      utils.removeExtFromMethod(method, extensionName, this.methods);
    });
  }

  /**
   * PUBLIC API OF AN INSTANCE
   */

  /**
   * Updates model language based on the path
   * @param {String} path - blob path
   */
  updateModelLanguage(path) {
    const lang = getBlobLanguage(path);
    const model = this.getModel();
    // return monacoEditor.setModelLanguage(model, lang);
    monacoEditor.setModelLanguage(model, lang);
  }

  /**
   * Main entry point to apply an extension to the instance
   * @param {SourceEditorExtensionDefinition[]|SourceEditorExtensionDefinition} extDefs - The extension(s) to use
   * @returns {EditorExtension|*}
   */
  use(extDefs) {
    return this.dispatchExtAction(this.useExtension, extDefs);
  }

  /**
   * Main entry point to remove an extension to the instance
   * @param {SourceEditorExtension[]|SourceEditorExtension} exts -
   * @returns {*}
   */
  unuse(exts) {
    return this.dispatchExtAction(this.unuseExtension, exts);
  }

  /**
   * Get the methods returned by extensions.
   * @returns {Array}
   */
  get extensionsAPI() {
    return Object.keys(this.methods);
  }
}
