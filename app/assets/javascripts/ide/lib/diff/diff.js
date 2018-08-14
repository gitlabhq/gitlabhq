import { diffLines } from 'diff';

// eslint-disable-next-line import/prefer-default-export
export const computeDiff = (originalContent, newContent) => {
  const changes = diffLines(originalContent, newContent);

  let lineNumber = 1;
  return changes.reduce((acc, change) => {
    const findOnLine = acc.find(c => c.lineNumber === lineNumber);

    if (findOnLine) {
      Object.assign(findOnLine, change, {
        modified: true,
        endLineNumber: (lineNumber + change.count) - 1,
      });
    } else if ('added' in change || 'removed' in change) {
      acc.push(Object.assign({}, change, {
        lineNumber,
        modified: undefined,
        endLineNumber: (lineNumber + change.count) - 1,
      }));
    }

    if (!change.removed) {
      lineNumber += change.count;
    }

    return acc;
  }, []);
};
