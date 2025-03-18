import axios from 'axios';
import { memoize } from 'lodash';

export const hasSelection = (tiptapEditor) => {
  const { from, to } = tiptapEditor.state.selection;

  return from < to;
};

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
