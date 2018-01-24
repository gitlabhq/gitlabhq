import DecorationsController from './decorations/controller';
import DirtyDiffController from './diff/controller';
import Disposable from './common/disposable';
import ModelManager from './common/model_manager';
import editorOptions from './editor_options';

export default class Editor {
  static create(monaco) {
    this.editorInstance = new Editor(monaco);

    return this.editorInstance;
  }

  constructor(monaco) {
    this.monaco = monaco;
    this.currentModel = null;
    this.instance = null;
    this.dirtyDiffController = null;
    this.disposable = new Disposable();

    this.disposable.add(
      this.modelManager = new ModelManager(this.monaco),
      this.decorationsController = new DecorationsController(this),
    );

    this.debouncedUpdate = _.debounce(() => {
      this.updateDimensions();
    }, 200);
    window.addEventListener('resize', this.debouncedUpdate, false);
  }

  createInstance(domElement) {
    if (!this.instance) {
      this.disposable.add(
        this.instance = this.monaco.editor.create(domElement, {
          model: null,
          readOnly: false,
          contextmenu: true,
          scrollBeyondLastLine: false,
          minimap: {
            enabled: false,
          },
        }),
        this.dirtyDiffController = new DirtyDiffController(
          this.modelManager, this.decorationsController,
        ),
      );
    }
  }

  createModel(file) {
    return this.modelManager.addModel(file);
  }

  attachModel(model) {
    this.instance.setModel(model.getModel());
    if (this.dirtyDiffController) this.dirtyDiffController.attachModel(model);

    this.currentModel = model;

    this.instance.updateOptions(editorOptions.reduce((acc, obj) => {
      Object.keys(obj).forEach((key) => {
        Object.assign(acc, {
          [key]: obj[key](model),
        });
      });
      return acc;
    }, {}));

    if (this.dirtyDiffController) this.dirtyDiffController.reDecorate(model);
  }

  clearEditor() {
    if (this.instance) {
      this.instance.setModel(null);
    }
  }

  dispose() {
    this.disposable.dispose();
    window.removeEventListener('resize', this.debouncedUpdate);

    // dispose main monaco instance
    if (this.instance) {
      this.instance = null;
    }
  }

  updateDimensions() {
    this.instance.layout();
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
    this.disposable.add(
      this.instance.onDidChangeCursorPosition(e => cb(this.instance, e)),
    );
  }
}
