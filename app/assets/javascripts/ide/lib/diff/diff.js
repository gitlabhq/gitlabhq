import { diffLines } from 'diff';
import { defaultDiffOptions } from '../editor_options';

export const computeDiff = (originalContent, newContent) => {
  // prevent EOL changes from highlighting the entire file
  const changes = diffLines(
    originalContent.replace(/\r\n/g, '\n'),
    newContent.replace(/\r\n/g, '\n'),
    defaultDiffOptions,
  );

  let lineNumber = 1;
  return changes.reduce((acc, change) => {
    const findOnLine = acc.find((c) => c.lineNumber === lineNumber);

    if (findOnLine) {
      Object.assign(findOnLine, change, {
        modified: true,
        endLineNumber: lineNumber + change.count - 1,
      });
    } else if ('added' in change || 'removed' in change) {
      acc.push({
        ...change,
        lineNumber,
        modified: undefined,
        endLineNumber: lineNumber + change.count - 1,
      });
    }

    if (!change.removed) {
      lineNumber += change.count;
    }

    return acc;
  }, []);
};
