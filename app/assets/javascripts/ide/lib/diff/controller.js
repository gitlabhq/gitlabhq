/* global monaco */
import { throttle } from 'underscore';
import DirtyDiffWorker from './diff_worker';
import Disposable from '../common/disposable';

export const getDiffChangeType = change => {
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
  range: new monaco.Range(change.lineNumber, 1, change.endLineNumber, 1),
  options: {
    isWholeLine: true,
    linesDecorationsClassName: `dirty-diff dirty-diff-${getDiffChangeType(
      change,
    )}`,
  },
});

export default class DirtyDiffController {
  constructor(modelManager, decorationsController) {
    this.disposable = new Disposable();
    this.editorSimpleWorker = null;
    this.modelManager = modelManager;
    this.decorationsController = decorationsController;
    this.dirtyDiffWorker = new DirtyDiffWorker();
    this.throttledComputeDiff = throttle(this.computeDiff, 250);
    this.decorate = this.decorate.bind(this);

    this.dirtyDiffWorker.addEventListener('message', this.decorate);
  }

  attachModel(model) {
    model.onChange(() => this.throttledComputeDiff(model));
  }

  computeDiff(model) {
    this.dirtyDiffWorker.postMessage({
      key: model.key,
      originalContent: model.getOriginalModel().getValue(),
      newContent: model.getModel().getValue(),
    });
  }

  reDecorate(model) {
    this.decorationsController.decorate(model);
  }

  decorate({ data }) {
    const decorations = data.changes.map(change => getDecorator(change));
    const model = this.modelManager.getModel(data.key);
    this.decorationsController.addDecorations(model, 'dirtyDiff', decorations);
  }

  dispose() {
    this.disposable.dispose();

    this.dirtyDiffWorker.removeEventListener('message', this.decorate);
    this.dirtyDiffWorker.terminate();
  }
}
