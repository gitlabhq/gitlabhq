import { HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';
import { findLineRow, getRowPosition, isRangeBoundary } from '~/rapid_diffs/utils/line_utils';
import { moveToggle } from '~/rapid_diffs/utils/new_discussion_toggle';

function getToggleSide(toggle) {
  const cell = toggle.closest('[data-position]');
  if (!cell) return undefined;
  const isInline = cell
    .closest('tr')
    .querySelector('[data-position="old"]:first-child + [data-position="new"]');
  return isInline ? undefined : cell.dataset.position;
}

function isCommentable(row, side) {
  const selector = side ? `[data-position="${side}"] [data-line-number]` : '[data-line-number]';
  return row.dataset.hunkLines != null && Boolean(row.querySelector(selector));
}

function getSelectionRange(rows, { startIdx, hoverIdx, side }) {
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

export function initLineRangeSelection(appElement) {
  const toggle = appElement.querySelector('[data-new-discussion-toggle]');
  let drag = null;
  toggle.setAttribute('draggable', 'true');

  function onDragStart(event) {
    const row = toggle.closest('[data-hunk-lines]');
    const side = getToggleSide(toggle);
    if (!row || !isCommentable(row, side)) return;

    toggle.dataset.dragging = '';
    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'copy'; // eslint-disable-line no-param-reassign
      event.dataTransfer.setData('text/plain', '');
    }

    const diffFile = toggle.closest('diff-file');
    diffFile.dataset.lineRangeDragging = '';
    const { rows } = row.closest('table');
    const lineRange = { start: getRowPosition(row, side), end: getRowPosition(row, side) };

    drag = { diffFile, side, startRow: row, rows, lineRange };
    diffFile.trigger(HIGHLIGHT_LINES, lineRange);
  }

  function onDragOver(event) {
    if (!drag) return;
    event.preventDefault();
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'copy'; // eslint-disable-line no-param-reassign

    const target = document.elementFromPoint(event.clientX, event.clientY);
    if (!target) return;
    const row = target.closest('tr');
    if (!row || !drag.diffFile.contains(row)) return;

    const lineRange = getSelectionRange(drag.rows, {
      startIdx: drag.startRow.rowIndex,
      hoverIdx: row.rowIndex,
      side: drag.side,
    });

    drag.lineRange = lineRange;
    drag.diffFile.trigger(HIGHLIGHT_LINES, lineRange);
  }

  function onDragEnd() {
    if (!drag) return;
    const { lineRange, diffFile, side } = drag;
    diffFile.trigger(CLEAR_HIGHLIGHT);
    delete diffFile.dataset.lineRangeDragging;
    drag = null;
    delete toggle.dataset.dragging;

    moveToggle(toggle, findLineRow(diffFile, lineRange.end.old_line, lineRange.end.new_line), side);
    toggle.hidden = false;
    diffFile.dataset.withDiscussionToggle = '';

    toggle.lineRange = lineRange;
    toggle.click();
  }

  toggle.addEventListener('dragstart', onDragStart);
  toggle.addEventListener('dragend', onDragEnd);
  appElement.addEventListener('dragover', onDragOver);
  appElement.addEventListener('drop', (event) => event.preventDefault());
}
