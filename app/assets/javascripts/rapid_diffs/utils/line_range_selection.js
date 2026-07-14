import { getRowPosition, isRangeBoundary } from '~/rapid_diffs/utils/line_utils';

export function isCommentable(row, side) {
  const selector = side ? `[data-position="${side}"] [data-line-number]` : '[data-line-number]';
  return row.dataset.hunkLines != null && Boolean(row.querySelector(selector));
}

export function getSelectionRange(rows, { startIdx, hoverIdx, side }) {
  const step = startIdx <= hoverIdx ? 1 : -1;
  let first = rows[startIdx];
  let last = first;
  for (let i = startIdx + step; i !== hoverIdx + step; i += step) {
    if (isRangeBoundary(rows[i])) break;
    if (isCommentable(rows[i], side)) last = rows[i];
  }
  if (step === -1) [first, last] = [last, first];
  return { start: getRowPosition(first, side), end: getRowPosition(last, side) };
}

export function getDragRange(diffFile, { rows, anchorRow, side, clientX, clientY }) {
  const row = document.elementFromPoint(clientX, clientY)?.closest('tr');
  if (!row || !diffFile.contains(row)) return null;
  return getSelectionRange(rows, { startIdx: anchorRow.rowIndex, hoverIdx: row.rowIndex, side });
}
