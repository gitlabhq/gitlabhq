/**
 * A WebIDE Extension options for Source Editor
 * @typedef {Object} WebIDEExtensionOptions
 * @property {Object} modelManager The root manager for WebIDE models
 * @property {Object} store The state store for communication
 * @property {Object} file
 * @property {Object} options The Monaco editor options
 */

import { KeyCode, KeyMod, Range } from 'monaco-editor';
import { EDITOR_TYPE_DIFF } from '~/editor/constants';
import Disposable from '~/ide/lib/common/disposable';
import { editorOptions } from '~/ide/lib/editor_options';
import keymap from '~/ide/lib/keymap.json';

const isDiffEditorType = (instance) => {
  return instance.getEditorType() === EDITOR_TYPE_DIFF;
};

export const UPDATE_DIMENSIONS_DELAY = 200;
const defaultOptions = {
  modelManager: undefined,
  store: undefined,
  file: undefined,
  options: {},
};

const addActions = (instance, store) => {
  const getKeyCode = (key) => {
    const monacoKeyMod = key.indexOf('KEY_') === 0;

    return monacoKeyMod ? KeyCode[key] : KeyMod[key];
  };

  keymap.forEach((command) => {
    const { bindings, id, label, action } = command;

    const keybindings = bindings.map((binding) => {
      const keys = binding.split('+');

      // eslint-disable-next-line no-bitwise
      return keys.length > 1 ? getKeyCode(keys[0]) | getKeyCode(keys[1]) : getKeyCode(keys[0]);
    });

    instance.addAction({
      id,
      label,
      keybindings,
      run() {
        store.dispatch(action.name, action.params);
        return null;
      },
    });
  });
};

const renderSideBySide = (domElement) => {
  return domElement.offsetWidth >= 700;
};

const updateDiffInstanceRendering = (instance) => {
  instance.updateOptions({
    renderSideBySide: renderSideBySide(instance.getDomNode()),
  });
};

export class EditorWebIdeExtension {
  static get extensionName() {
    return 'EditorWebIde';
  }

  /**
   * Set up the WebIDE extension for Source Editor
   * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
   * @param {WebIDEExtensionOptions} setupOptions
   */
  onSetup(instance, setupOptions = defaultOptions) {
    this.modelManager = setupOptions.modelManager;
    this.store = setupOptions.store;
    this.file = setupOptions.file;
    this.options = setupOptions.options;

    this.disposable = new Disposable();
    addActions(instance, setupOptions.store);

    if (isDiffEditorType(instance)) {
      updateDiffInstanceRendering(instance);
      instance.getModifiedEditor().onDidLayoutChange(() => {
        updateDiffInstanceRendering(instance);
      });
    }

    instance.onDidDispose(() => {
      this.onUnuse();
    });
  }

  onUnuse() {
    // catch any potential errors with disposing the error
    // this is mainly for tests caused by elements not existing
    try {
      this.disposable.dispose();
    } catch (e) {
      if (process.env.NODE_ENV !== 'test') {
        // eslint-disable-next-line no-console
        console.error(e);
      }
    }
  }

  provides() {
    return {
      createModel: (instance, file, head = null) => {
        return this.modelManager.addModel(file, head);
      },
      attachModel: (instance, model) => {
        if (isDiffEditorType(instance)) {
          instance.setModel({
            original: model.getOriginalModel(),
            modified: model.getModel(),
          });

          return;
        }

        instance.setModel(model.getModel());

        instance.updateOptions(
          editorOptions.reduce((acc, obj) => {
            Object.keys(obj).forEach((key) => {
              Object.assign(acc, {
                [key]: obj[key](model),
              });
            });
            return acc;
          }, {}),
        );
      },
      attachMergeRequestModel: (instance, model) => {
        instance.setModel({
          original: model.getBaseModel(),
          modified: model.getModel(),
        });
      },
      setPos: (instance, { lineNumber, column }) => {
        instance.revealPositionInCenter({
          lineNumber,
          column,
        });
        instance.setPosition({
          lineNumber,
          column,
        });
      },
      onPositionChange: (instance, cb) => {
        if (typeof instance.onDidChangeCursorPosition !== 'function') {
          return;
        }

        this.disposable.add(instance.onDidChangeCursorPosition((e) => cb(instance, e)));
      },
      replaceSelectedText: (instance, text) => {
        let selection = instance.getSelection();
        const range = new Range(
          selection.startLineNumber,
          selection.startColumn,
          selection.endLineNumber,
          selection.endColumn,
        );

        instance.executeEdits('', [{ range, text }]);

        selection = instance.getSelection();
        instance.setPosition({ lineNumber: selection.endLineNumber, column: selection.endColumn });
      },
    };
  }
}
