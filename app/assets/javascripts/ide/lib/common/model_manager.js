import eventHub from '../../eventhub';
import Disposable from './disposable';
import Model from './model';

export default class ModelManager {
  constructor(monaco) {
    this.monaco = monaco;
    this.disposable = new Disposable();
    this.models = new Map();
  }

  hasCachedModel(key) {
    return this.models.has(key);
  }

  getModel(key) {
    return this.models.get(key);
  }

  addModel(file) {
    if (this.hasCachedModel(file.key)) {
      return this.getModel(file.key);
    }

    const model = new Model(this.monaco, file);
    this.models.set(model.path, model);
    this.disposable.add(model);

    eventHub.$on(
      `editor.update.model.dispose.${file.key}`,
      this.removeCachedModel.bind(this, file),
    );

    return model;
  }

  removeCachedModel(file) {
    this.models.delete(file.key);

    eventHub.$off(`editor.update.model.dispose.${file.key}`, this.removeCachedModel);
  }

  dispose() {
    // dispose of all the models
    this.disposable.dispose();
    this.models.clear();
  }
}
