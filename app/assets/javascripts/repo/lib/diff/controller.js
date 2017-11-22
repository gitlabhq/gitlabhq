/* global monaco */
import DirtyDiffWorker from './worker';
import Disposable from '../common/disposable';
import decorationsController from '../decorations/controller';

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

export const decorate = (model, changes) => {
  const decorations = changes.map(change => getDecorator(change));
  decorationsController.addDecorations(model, 'dirtyDiff', decorations);
};

export default class DirtyDiffController {
  constructor(modelManager) {
    this.disposable = new Disposable();
    this.editorSimpleWorker = null;
    this.modelManager = modelManager;
    this.dirtyDiffWorker = new DirtyDiffWorker();
  }

  attachModel(model) {
    model.onChange(() => this.computeDiff(model));
  }

  computeDiff(model) {
    decorate(model, this.dirtyDiffWorker.compute(model));
  }

  // eslint-disable-next-line class-methods-use-this
  reDecorate(model) {
    decorationsController.decorate(model);
  }

  dispose() {
    this.disposable.dispose();
  }
}
