/* global monaco */
import Disposable from '../common/disposable';
import DirtyDiffWorker from './worker';
import decorationsController from '../decorations/controller';

export const getDiffChangeType = (change) => {
  if (change.originalEndLineNumber === 0) {
    return 'added';
  } else if (change.modifiedEndLineNumber === 0) {
    return 'removed';
  }

  return 'modified';
};

export const getDecorator = change => ({
  range: new monaco.Range(
    change.modifiedStartLineNumber,
    1,
    !change.modifiedEndLineNumber ?
      change.modifiedStartLineNumber : change.modifiedEndLineNumber,
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
    this.disposable.add(this.worker = new DirtyDiffWorker());
  }

  attachModel(model) {
    if (model.attachedToWorker) return;

    [model.getModel(), model.getOriginalModel()].forEach(() => {
      this.worker.attachModel(model);
    });

    model.onChange((_, e) => this.computeDiff(model, e));
  }

  computeDiff(model, e) {
    this.worker.modelChanged(model, e);
    this.worker.compute(model, changes => decorate(model, changes));
  }

  // eslint-disable-next-line class-methods-use-this
  reDecorate(model) {
    decorationsController.decorate(model);
  }

  dispose() {
    this.disposable.dispose();
  }
}
