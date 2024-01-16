import { isString } from 'lodash';

export const getFullSource = (element) => {
  const commentNode = element.ownerDocument.body.lastChild;

  if (commentNode?.nodeName === '#comment' && isString(commentNode.textContent)) {
    return commentNode.textContent.split('\n');
  }

  return [];
};

const getRangeFromSourcePos = (sourcePos) => {
  const [start, end] = sourcePos.split('-');
  const [startRow, startCol] = start.split(':');
  const [endRow, endCol] = end.split(':');

  return {
    start: { row: Math.max(0, Number(startRow) - 1), col: Math.max(0, Number(startCol) - 1) },
    end: { row: Math.max(0, Number(endRow) - 1), col: Math.max(0, Number(endCol) - 1) },
  };
};

export const getMarkdownSource = (element) => {
  if (!element.dataset.sourcepos) return undefined;

  try {
    const source = getFullSource(element);
    const range = getRangeFromSourcePos(element.dataset.sourcepos);
    let elSource = '';

    if (!source.length) return undefined;

    for (let i = range.start.row; i <= range.end.row; i += 1) {
      if (i === range.start.row) {
        elSource += source[i].substring(range.start.col);
      } else {
        elSource += `\n${source[i]}` || '';
      }
    }

    return elSource.trim();
  } catch {
    return undefined;
  }
};
