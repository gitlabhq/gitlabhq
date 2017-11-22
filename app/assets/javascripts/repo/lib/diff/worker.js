import { diffLines } from 'diff';

export default class DirtyDiffWorker {
  // eslint-disable-next-line class-methods-use-this
  compute(model) {
    const originalContent = model.getOriginalModel().getValue();
    const newContent = model.getModel().getValue();
    const changes = diffLines(originalContent, newContent);

    let lineNumber = 1;
    return changes.reduce((acc, change) => {
      const findOnLine = acc.find(c => c.lineNumber === lineNumber);

      if (findOnLine) {
        Object.assign(findOnLine, change, {
          modified: true,
          endLineNumber: change.count > 1 ? lineNumber + change.count : lineNumber,
        });
      } else if ('added' in change || 'removed' in change) {
        acc.push(Object.assign({}, change, {
          lineNumber,
          modified: undefined,
          endLineNumber: change.count > 1 ? lineNumber + change.count : lineNumber,
        }));
      }

      if (!change.removed) {
        lineNumber += change.count;
      }

      return acc;
    }, []);
  }
}
