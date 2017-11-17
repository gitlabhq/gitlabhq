/* global monaco */
import DirtyDiffController from './diff/controller';
import Model from './common/model';

class Editor {
  constructor() {
    this.models = new Map();
    this.diffComputers = new Map();
    this.currentModel = null;
    this.instance = null;
    this.dirtyDiffController = null;
  }

  createInstance(domElement) {
    if (!this.instance) {
      this.instance = monaco.editor.create(domElement, {
        model: null,
        readOnly: false,
        contextmenu: true,
        scrollBeyondLastLine: false,
      });

      this.dirtyDiffController = new DirtyDiffController();
    }
  }

  createModel(file) {
    if (this.models.has(file.path)) {
      return this.models.get(file.path);
    }

    const model = new Model(file);
    this.models.set(file.path, model);

    return model;
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
    // dispose main monaco instance
    if (this.instance) {
      this.instance.dispose();
      this.instance = null;
    }

    // dispose of all the models
    this.models.forEach(model => model.dispose());
    this.models.clear();

    this.dirtyDiffController.dispose();
    this.dirtyDiffController = null;
  }
}

export default new Editor();
