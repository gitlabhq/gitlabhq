import { identity } from 'lodash';

const preserveMarkdown = () => gon.features?.preserveMarkdown;

export const docHasSourceMap = (element) => {
  const commentNode = element.ownerDocument.body.lastChild;
  return Boolean(commentNode?.nodeName === '#comment' && commentNode.textContent);
};

export const getFullSource = (element) => {
  const commentNode = element.ownerDocument.body.lastChild;

  if (commentNode?.nodeName === '#comment' && commentNode.textContent) {
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

const getMarkdownSourceKey = (element) => {
  return element.dataset.sourcepos;
};

const getSourceTagName = (element) => {
  if (!docHasSourceMap(element)) return undefined;
  return element.tagName.toLowerCase();
};

export const getMarkdownSource = (element) => {
  if (!element.dataset.sourcepos) return undefined;

  try {
    const source = getFullSource(element);
    const range = getRangeFromSourcePos(element.dataset.sourcepos);
    let elSource = '';

    if (!source.length) return undefined;

    for (let i = range.start.row; i <= range.end.row; i += 1) {
      if (i === range.start.row && i === range.end.row) {
        elSource += source[i].substring(range.start.col, range.end.col + 1);
      } else if (i === range.start.row) {
        elSource += source[i]?.substring(range.start.col) || '';
      } else if (i === range.end.row) {
        elSource += `\n${source[i]?.substring(0, range.end.col + 1) || ''}`;
      } else {
        elSource += `\n${source[i]}` || '';
      }
    }

    return elSource;
  } catch {
    return undefined;
  }
};

export const getSourceMapAttributes = (queryElement = identity) => {
  return {
    sourceMarkdown: {
      default: null,
      parseHTML: (el) => (preserveMarkdown() ? getMarkdownSource(queryElement(el)) : null),
      renderHTML: () => '',
    },
    sourceMapKey: {
      default: null,
      parseHTML: (el) => (preserveMarkdown() ? getMarkdownSourceKey(queryElement(el)) : null),
      renderHTML: () => '',
    },
    sourceTagName: {
      default: null,
      parseHTML: (el) => (preserveMarkdown() ? getSourceTagName(queryElement(el)) : null),
      renderHTML: () => '',
    },
  };
};
