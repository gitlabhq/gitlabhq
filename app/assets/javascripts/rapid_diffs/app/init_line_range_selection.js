import { HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';
import { findLineRow, getRowPosition } from '~/rapid_diffs/utils/line_utils';
import { getDragRange, isCommentable } from '~/rapid_diffs/utils/line_range_selection';
import { moveToggle } from '~/rapid_diffs/utils/new_discussion_toggle';

function getToggleSide(toggle) {
  const cell = toggle.closest('[data-position]');
  if (!cell) return undefined;
  const isInline = cell
    .closest('tr')
    .querySelector('[data-position="old"]:first-child + [data-position="new"]');
  return isInline ? undefined : cell.dataset.position;
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

    const lineRange = getDragRange(drag.diffFile, {
      rows: drag.rows,
      anchorRow: drag.startRow,
      side: drag.side,
      clientX: event.clientX,
      clientY: event.clientY,
    });
    if (!lineRange) return;
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
