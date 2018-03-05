import Disposable from './disposable';
import Model from './model';

export default class ModelManager {
  constructor(monaco) {
    this.monaco = monaco;
    this.disposable = new Disposable();
    this.models = new Map();
  }

  hasCachedModel(path) {
    return this.models.has(path);
  }

  getModel(path) {
    return this.models.get(path);
  }

  addModel(file) {
    if (this.hasCachedModel(file.path)) {
      return this.getModel(file.path);
    }

    const model = new Model(this.monaco, file);
    this.models.set(model.path, model);
    this.disposable.add(model);

    return model;
  }

  dispose() {
    // dispose of all the models
    this.disposable.dispose();
    this.models.clear();
  }
}
