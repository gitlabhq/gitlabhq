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
    start: { row: Number(startRow) - 1, col: Number(startCol) - 1 },
    end: { row: Number(endRow) - 1, col: Number(endCol) - 1 },
  };
};

export const getMarkdownSource = (element) => {
  if (!element.dataset.sourcepos) return undefined;

  const source = getFullSource(element);
  const range = getRangeFromSourcePos(element.dataset.sourcepos);
  let elSource = '';

  if (!source.length) return undefined;

  for (let i = range.start.row; i <= range.end.row; i += 1) {
    if (i === range.start.row) {
      elSource += source[i].substring(range.start.col);
    } else if (i === range.end.row) {
      elSource += `\n${source[i]?.substring(0, range.start.col)}`;
    } else {
      elSource += `\n${source[i]}` || '';
    }
  }

  return elSource.trim();
};
