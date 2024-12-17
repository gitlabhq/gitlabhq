import { preserveUnchanged } from '../serialization_helpers';
import { renderList } from './bullet_list';

export function renderOrderedList(state, node) {
  const { sourceMarkdown } = node.attrs;
  let start;
  let delimiter;

  if (sourceMarkdown) {
    const match = /^(\d+)(\)|\.)/.exec(sourceMarkdown.trim());
    start = parseInt(match[1], 10) || 1;
    [, , delimiter] = match;
  } else {
    start = node.attrs.start || 1;
    delimiter = node.attrs.parens ? ')' : '.';
  }

  const maxW = String(start + node.childCount - 1).length;
  const space = state.repeat(' ', maxW + 2);

  renderList(state, node, space, (i) => {
    const nStr = String(start + i);
    return `${state.repeat(' ', maxW - nStr.length) + nStr}${delimiter} `;
  });
}

const orderedList = preserveUnchanged(renderOrderedList);

export default orderedList;
