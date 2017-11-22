/* global monaco */
import DirtyDiffWorker from 'worker-loader!./worker.diff';
import Disposable from '../common/disposable';

export const getDiffChangeType = (change) => {
  if (change.modified) {
    return 'modified';
  } else if (change.added) {
    return 'added';
  } else if (change.removed) {
    return 'removed';
  }

  return '';
};

export const getDecorator = change => ({
  range: new monaco.Range(
    change.lineNumber,
    1,
    change.endLineNumber,
    1,
  ),
  options: {
    isWholeLine: true,
    linesDecorationsClassName: `dirty-diff dirty-diff-${getDiffChangeType(change)}`,
  },
});

export default class DirtyDiffController {
  constructor(modelManager, decorationsController) {
    this.disposable = new Disposable();
    this.editorSimpleWorker = null;
    this.modelManager = modelManager;
    this.decorationsController = decorationsController;
    this.dirtyDiffWorker = new DirtyDiffWorker();

    this.dirtyDiffWorker.addEventListener('message', e => this.decorate(e));
  }

  attachModel(model) {
    model.onChange(() => this.computeDiff(model));
  }

  computeDiff(model) {
    this.dirtyDiffWorker.postMessage({
      path: model.path,
      originalContent: model.getOriginalModel().getValue(),
      newContent: model.getModel().getValue(),
    });
  }

  reDecorate(model) {
    this.decorationsController.decorate(model);
  }

  decorate({ data }) {
    const decorations = data.changes.map(change => getDecorator(change));
    this.decorationsController.addDecorations(data.path, 'dirtyDiff', decorations);
  }

  dispose() {
    this.disposable.dispose();
    this.dirtyDiffWorker.terminate();
  }
}
