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
    linesDecorationsClassName: `dirty-diff dirty-diff-${getDiffChangeType(change)}`,
  },
});

export default class DirtyDiffController {
  constructor(modelManager, decorationsController) {
    this.disposable = new Disposable();
    this.models = new Map();
    this.editorSimpleWorker = null;
    this.modelManager = modelManager;
    this.decorationsController = decorationsController;
    this.dirtyDiffWorker = new DirtyDiffWorker();
    this.throttledComputeDiff = throttle(this.computeDiff, 250);
    this.decorate = this.decorate.bind(this);

    this.dirtyDiffWorker.addEventListener('message', this.decorate);
  }

  attachModel(model) {
    if (this.models.has(model.url)) return;

    model.onChange(() => this.throttledComputeDiff(model));
    model.onDispose(() => {
      this.decorationsController.removeDecorations(model);
      this.models.delete(model.url);
    });

    this.models.set(model.url, model);
  }

  computeDiff(model) {
    this.dirtyDiffWorker.postMessage({
      path: model.path,
      originalContent: model.getOriginalModel().getValue(),
      newContent: model.getModel().getValue(),
    });
  }

  reDecorate(model) {
    if (this.decorationsController.hasDecorations(model)) {
      this.decorationsController.decorate(model);
    } else {
      this.computeDiff(model);
    }
  }

  decorate({ data }) {
    const decorations = data.changes.map(change => getDecorator(change));
    const model = this.modelManager.getModel(data.path);
    this.decorationsController.addDecorations(model, 'dirtyDiff', decorations);
  }

  dispose() {
    this.disposable.dispose();
    this.models.clear();

    this.dirtyDiffWorker.removeEventListener('message', this.decorate);
    this.dirtyDiffWorker.terminate();
  }
}
