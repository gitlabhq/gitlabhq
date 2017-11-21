import Disposable from './disposable';
import Model from './model';

export default class ModelManager {
  constructor() {
    this.disposable = new Disposable();
    this.models = new Map();
  }

  hasCachedModel(path) {
    return this.models.has(path);
  }

  addModel(file) {
    if (this.hasCachedModel(file.path)) {
      return this.models.get(file.path);
    }

    const model = new Model(file);
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
