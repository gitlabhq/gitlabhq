/* global monaco */
export default class DirtyDiffWorker {
  constructor() {
    this.editorSimpleWorker = null;
    this.models = new Map();
    this.actions = new Set();

    // eslint-disable-next-line promise/catch-or-return
    monaco.editor.createWebWorker({
      moduleId: 'vs/editor/common/services/editorSimpleWorker',
    }).getProxy().then((editorSimpleWorker) => {
      this.editorSimpleWorker = editorSimpleWorker;
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
    if (this.editorSimpleWorker && !this.models.has(model.url)) {
      this.editorSimpleWorker.acceptNewModel(model);

      this.models.set(model.url, model);
    } else if (!this.editorSimpleWorker) {
      this.actions.add({
        attachModel: [model],
      });
    }
  }

  modelChanged(model, e) {
    if (this.editorSimpleWorker) {
      this.editorSimpleWorker.acceptModelChanged(
        model.getModel().uri.toString(),
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
      // eslint-disable-next-line promise/catch-or-return
      this.editorSimpleWorker.computeDiff(
        model.getOriginalModel().uri.toString(),
        model.getModel().uri.toString(),
      ).then(cb);
    } else {
      this.actions.add({
        compute: [model, cb],
      });
    }
  }

  dispose() {
    this.models.forEach(model =>
      this.editorSimpleWorker.acceptRemovedModel(model.url),
    );
    this.models.clear();

    this.actions.clear();

    this.editorSimpleWorker.dispose();
    this.editorSimpleWorker = null;
  }
}
