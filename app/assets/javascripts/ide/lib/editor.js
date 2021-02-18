import { debounce } from 'lodash';
import { editor as monacoEditor, KeyCode, KeyMod, Range } from 'monaco-editor';
import { clearDomElement } from '~/editor/utils';
import { registerLanguages } from '../utils';
import Disposable from './common/disposable';
import ModelManager from './common/model_manager';
import DecorationsController from './decorations/controller';
import DirtyDiffController from './diff/controller';
import { editorOptions, defaultEditorOptions, defaultDiffEditorOptions } from './editor_options';
import keymap from './keymap.json';
import languages from './languages';
import { themes } from './themes';

function setupThemes() {
  themes.forEach((theme) => {
    monacoEditor.defineTheme(theme.name, theme.data);
  });
}

export default class Editor {
  static create(...args) {
    if (!this.editorInstance) {
      this.editorInstance = new Editor(...args);
    }
    return this.editorInstance;
  }

  constructor(store, options = {}) {
    this.currentModel = null;
    this.instance = null;
    this.dirtyDiffController = null;
    this.disposable = new Disposable();
    this.modelManager = new ModelManager();
    this.decorationsController = new DecorationsController(this);
    this.options = {
      ...defaultEditorOptions,
      ...options,
    };
    this.diffOptions = {
      ...defaultDiffEditorOptions,
      ...options,
    };
    this.store = store;

    setupThemes();
    registerLanguages(...languages);

    this.debouncedUpdate = debounce(() => {
      this.updateDimensions();
    }, 200);
  }

  createInstance(domElement) {
    if (!this.instance) {
      clearDomElement(domElement);

      this.disposable.add(
        (this.instance = monacoEditor.create(domElement, {
          ...this.options,
        })),
        (this.dirtyDiffController = new DirtyDiffController(
          this.modelManager,
          this.decorationsController,
        )),
      );

      this.addCommands();

      window.addEventListener('resize', this.debouncedUpdate, false);
    }
  }

  createDiffInstance(domElement) {
    if (!this.instance) {
      clearDomElement(domElement);

      this.disposable.add(
        (this.instance = monacoEditor.createDiffEditor(domElement, {
          ...this.diffOptions,
          renderSideBySide: Editor.renderSideBySide(domElement),
        })),
      );

      this.addCommands();

      window.addEventListener('resize', this.debouncedUpdate, false);
    }
  }

  createModel(file, head = null) {
    return this.modelManager.addModel(file, head);
  }

  attachModel(model) {
    if (this.isDiffEditorType) {
      this.instance.setModel({
        original: model.getOriginalModel(),
        modified: model.getModel(),
      });

      return;
    }

    this.instance.setModel(model.getModel());
    if (this.dirtyDiffController) this.dirtyDiffController.attachModel(model);

    this.currentModel = model;

    this.instance.updateOptions(
      editorOptions.reduce((acc, obj) => {
        Object.keys(obj).forEach((key) => {
          Object.assign(acc, {
            [key]: obj[key](model),
          });
        });
        return acc;
      }, {}),
    );

    if (this.dirtyDiffController) this.dirtyDiffController.reDecorate(model);
  }

  attachMergeRequestModel(model) {
    this.instance.setModel({
      original: model.getBaseModel(),
      modified: model.getModel(),
    });

    monacoEditor.createDiffNavigator(this.instance, {
      alwaysRevealFirst: true,
    });
  }

  clearEditor() {
    if (this.instance) {
      this.instance.setModel(null);
    }
  }

  dispose() {
    window.removeEventListener('resize', this.debouncedUpdate);

    // catch any potential errors with disposing the error
    // this is mainly for tests caused by elements not existing
    try {
      this.disposable.dispose();

      this.instance = null;
    } catch (e) {
      this.instance = null;

      if (process.env.NODE_ENV !== 'test') {
        // eslint-disable-next-line no-console
        console.error(e);
      }
    }
  }

  updateDimensions() {
    if (this.instance) {
      this.instance.layout();
      this.updateDiffView();
    }
  }

  setPosition({ lineNumber, column }) {
    this.instance.revealPositionInCenter({
      lineNumber,
      column,
    });
    this.instance.setPosition({
      lineNumber,
      column,
    });
  }

  onPositionChange(cb) {
    if (!this.instance.onDidChangeCursorPosition) return;

    this.disposable.add(this.instance.onDidChangeCursorPosition((e) => cb(this.instance, e)));
  }

  updateDiffView() {
    if (!this.isDiffEditorType) return;

    this.instance.updateOptions({
      renderSideBySide: Editor.renderSideBySide(this.instance.getDomNode()),
    });
  }

  replaceSelectedText(text) {
    let selection = this.instance.getSelection();
    const range = new Range(
      selection.startLineNumber,
      selection.startColumn,
      selection.endLineNumber,
      selection.endColumn,
    );

    this.instance.executeEdits('', [{ range, text }]);

    selection = this.instance.getSelection();
    this.instance.setPosition({ lineNumber: selection.endLineNumber, column: selection.endColumn });
  }

  get isDiffEditorType() {
    return this.instance.getEditorType() === 'vs.editor.IDiffEditor';
  }

  static renderSideBySide(domElement) {
    return domElement.offsetWidth >= 700;
  }

  addCommands() {
    const { store } = this;
    const getKeyCode = (key) => {
      const monacoKeyMod = key.indexOf('KEY_') === 0;

      return monacoKeyMod ? KeyCode[key] : KeyMod[key];
    };

    keymap.forEach((command) => {
      const keybindings = command.bindings.map((binding) => {
        const keys = binding.split('+');

        // eslint-disable-next-line no-bitwise
        return keys.length > 1 ? getKeyCode(keys[0]) | getKeyCode(keys[1]) : getKeyCode(keys[0]);
      });

      this.instance.addAction({
        id: command.id,
        label: command.label,
        keybindings,
        run() {
          store.dispatch(command.action.name, command.action.params);
          return null;
        },
      });
    });
  }
}
