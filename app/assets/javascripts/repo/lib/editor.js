/* global monaco */
import DirtyDiffController from './diff/controller';
import Disposable from './common/disposable';
import ModelManager from './common/model_manager';

export default class Editor {
  static create() {
    this.editorInstance = new Editor();

    return this.editorInstance;
  }

  constructor() {
    this.currentModel = null;
    this.instance = null;
    this.dirtyDiffController = null;
    this.disposable = new Disposable();

    this.disposable.add(
      this.modelManager = new ModelManager(),
    );
  }

  createInstance(domElement) {
    if (!this.instance) {
      this.disposable.add(
        this.instance = monaco.editor.create(domElement, {
          model: null,
          readOnly: false,
          contextmenu: true,
          scrollBeyondLastLine: false,
        }),
        this.dirtyDiffController = new DirtyDiffController(this.modelManager),
      );
    }
  }

  createModel(file) {
    return this.modelManager.addModel(file);
  }

  attachModel(model) {
    this.instance.setModel(model.getModel());
    this.dirtyDiffController.attachModel(model);

    this.currentModel = model;

    this.dirtyDiffController.reDecorate(model);
  }

  clearEditor() {
    if (this.instance) {
      this.instance.setModel(null);
    }
  }

  dispose() {
    this.disposable.dispose();

    // dispose main monaco instance
    if (this.instance) {
      this.instance = null;
    }
  }
}
