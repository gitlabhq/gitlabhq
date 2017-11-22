/* global monaco */
import DirtyDiffWorker from './diff';
console.log(DirtyDiffWorker);
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
    console.log(DirtyDiffWorker);
    // this.dirtyDiffWorker = new DirtyDiffWorker();
  }

  attachModel(model) {
    model.onChange(() => this.computeDiff(model));
  }

  computeDiff(model) {
    this.decorate(model, this.dirtyDiffWorker.compute(model));
  }

  // eslint-disable-next-line class-methods-use-this
  reDecorate(model) {
    this.decorationsController.decorate(model);
  }

  decorate(model, changes) {
    const decorations = changes.map(change => getDecorator(change));
    this.decorationsController.addDecorations(model, 'dirtyDiff', decorations);
  }

  dispose() {
    this.disposable.dispose();
  }
}
