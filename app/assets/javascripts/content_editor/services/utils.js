import { memoize } from 'lodash';
import axios from '~/lib/utils/axios_utils';

export const clamp = (n, min, max) => Math.max(Math.min(n, max), min);

export const memoizedGet = memoize(async (path) => {
  const { data } = await axios(path, { responseType: 'blob' });
  return data.text();
});

/**
 * Creates a union rectangle from any number of DOMRect objects
 * @param {...(DOMRect|null|undefined)} rects - Rectangle objects to union
 * @returns {DOMRect} A new DOMRect representing the union of all input rectangles
 */
export const rectUnion = (...rects) => {
  const validRects = rects.filter((rect) => rect);

  if (!validRects.length) return new DOMRect(-1000, -1000, 0, 0);
  if (validRects.length === 1) return validRects[0];

  let left = Infinity;
  let top = Infinity;
  let right = -Infinity;
  let bottom = -Infinity;

  for (const rect of validRects) {
    left = Math.min(left, rect.left);
    top = Math.min(top, rect.top);
    right = Math.max(right, rect.right);
    bottom = Math.max(bottom, rect.bottom);
  }

  return new DOMRect(left, top, right - left, bottom - top);
};

// Return the text in the header cell for the column `pos` is in.
// `pos` is assumed to be a table task item.
// This is used to create the aria-label for a task table item.
export const getColumnHeaderText = (doc, pos) => {
  const resolvedPos = doc.resolve(pos);
  const cell = resolvedPos.node(resolvedPos.depth - 1);
  const row = resolvedPos.node(resolvedPos.depth - 2);
  const table = resolvedPos.node(resolvedPos.depth - 3);

  if (table.type.name !== 'table') return null;

  let columnIndex = null;
  row.forEach((child, _, index) => {
    if (child.eq(cell)) {
      columnIndex = index;
    }
  });

  if (columnIndex === null) return null;

  const firstRow = table.child(0);

  const headerCell = firstRow.maybeChild(columnIndex);
  if (!headerCell) return null;

  let headerText = '';
  headerCell.forEach((node) => {
    if (node.type.name === 'paragraph') {
      headerText = node.textContent;
    }
  });

  return headerText;
};
