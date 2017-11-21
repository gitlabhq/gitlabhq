/* global monaco */
import Disposable from '../common/disposable';

export default class DirtyDiffWorker {
  constructor() {
    this.editorSimpleWorker = null;
    this.disposable = new Disposable();
    this.actions = new Set();

    // eslint-disable-next-line promise/catch-or-return
    monaco.editor.createWebWorker({
      moduleId: 'vs/editor/common/services/editorSimpleWorker',
    }).getProxy().then((editorSimpleWorker) => {
      this.disposable.add(this.editorSimpleWorker = editorSimpleWorker);
      this.ready();
    });
  }

  // loop through all the previous cached actions
  // this way we don't block the user from editing the file
  ready() {
    this.actions.forEach((action) => {
      const methodName = Object.keys(action)[0];
      this[methodName](...action[methodName]);
    });

    this.actions.clear();
  }

  attachModel(model) {
    if (this.editorSimpleWorker && !model.attachedToWorker) {
      this.editorSimpleWorker.acceptNewModel(model.diffModel);
      this.editorSimpleWorker.acceptNewModel(model.originalDiffModel);

      model.setAttachedToWorker(true);
    } else if (!this.editorSimpleWorker) {
      this.actions.add({
        attachModel: [model],
      });
    }
  }

  modelChanged(model, e) {
    if (this.editorSimpleWorker) {
      this.editorSimpleWorker.acceptModelChanged(
        model.url,
        e,
      );
    } else {
      this.actions.add({
        modelChanged: [model, e],
      });
    }
  }

  compute(model, cb) {
    if (this.editorSimpleWorker) {
      return this.editorSimpleWorker.computeDiff(
        model.originalUrl,
        model.url,
      ).then(cb);
    }

    this.actions.add({
      compute: [model, cb],
    });

    return null;
  }

  dispose() {
    this.actions.clear();

    this.disposable.dispose();
    this.editorSimpleWorker = null;
  }
}
