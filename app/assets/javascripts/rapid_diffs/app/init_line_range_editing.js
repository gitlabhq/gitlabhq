import { watch } from 'vue';
import { pinia } from '~/pinia/instance';
import { __ } from '~/locale';
import { spriteIconElement } from '~/lib/utils/common_utils';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';
import {
  findLineRow,
  getLineChange,
  getLineCode,
  getLineNumbers,
  getNewLineRangeContent,
  isRangeBoundary,
} from '~/rapid_diffs/utils/line_utils';
import {
  getDragRange,
  getSelectionRange,
  isCommentable,
} from '~/rapid_diffs/utils/line_range_selection';

const INLINE_SELECTOR = '[data-position="old"]:first-child + [data-position="new"]';
const ICON_CLASS = 'gl-icon s12 gl-fill-current';
const INSTRUCTIONS_ID = 'rd-line-range-editing-instructions';

function gutterCell(row, side) {
  if (row.querySelector(INLINE_SELECTOR)) return row.querySelector('[data-position]');
  return row.querySelector(`[data-position="${side}"]`);
}

function detectSide(diffElement, { discussion, lineRange }) {
  if (diffElement.querySelector(INLINE_SELECTOR)) return undefined;
  return discussion.lineChange?.position ?? (lineRange.end.new_line != null ? 'new' : 'old');
}

function createHandle(type) {
  const handle = document.createElement('button');
  handle.type = 'button';
  handle.className = 'rd-line-range-handle';
  handle.dataset.lineRangeHandle = type;
  handle.setAttribute('draggable', 'true');
  handle.setAttribute('aria-describedby', INSTRUCTIONS_ID);
  handle.setAttribute(
    'aria-label',
    type === 'start'
      ? __('Drag to change the first line of the comment')
      : __('Drag to change the last line of the comment'),
  );
  handle.appendChild(spriteIconElement('grip', ICON_CLASS));
  return handle;
}

function createCancelButton() {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'rd-line-range-cancel';
  button.dataset.lineRangeCancel = '';
  button.setAttribute('aria-describedby', INSTRUCTIONS_ID);
  button.setAttribute('aria-label', __('Cancel editing the comment line range'));
  button.appendChild(spriteIconElement('close', 'gl-icon s16 gl-fill-current'));
  return button;
}

function createInstructions() {
  const instructions = document.createElement('div');
  instructions.id = INSTRUCTIONS_ID;
  instructions.className = 'gl-sr-only';
  instructions.textContent = __(
    'Editing the comment line range. Use the Up and Down arrow keys to adjust the selection, press Enter to confirm, or Escape to cancel.',
  );
  return instructions;
}

export function initLineRangeEditing(appElement, store = useMergeRequestDiscussions(pinia)) {
  let session = null;

  function findDiffFile({ oldPath, newPath }) {
    return [...appElement.querySelectorAll('diff-file')].find(
      (file) => file.data.oldPath === oldPath && file.data.newPath === newPath,
    );
  }

  function clearHandleRows() {
    for (const row of session.diffElement.querySelectorAll('[data-line-range-handle-row]')) {
      delete row.dataset.lineRangeHandleRow;
    }
  }

  function placeControls() {
    const { diffElement, side, editing, handles, cancelButton } = session;
    const { lineRange } = editing;
    const startRow = findLineRow(diffElement, lineRange.start.old_line, lineRange.start.new_line);
    const endRow = findLineRow(diffElement, lineRange.end.old_line, lineRange.end.new_line);
    if (!startRow || !endRow) return false;
    const startCell = gutterCell(startRow, side);
    const endCell = gutterCell(endRow, side);
    if (!startCell || !endCell) return false;
    clearHandleRows();
    startRow.dataset.lineRangeHandleRow = '';
    endRow.dataset.lineRangeHandleRow = '';
    startCell.prepend(handles.start, cancelButton);
    endCell.prepend(handles.end);
    return true;
  }

  function highlight() {
    session.diffFile.trigger(HIGHLIGHT_LINES, session.editing.lineRange);
  }

  function commit() {
    const { diffElement, diffFile, side, editing } = session;
    const { lineRange } = editing;
    const endRow = findLineRow(diffElement, lineRange.end.old_line, lineRange.end.new_line);
    if (!endRow) {
      store.cancelLineRangeEditing();
      return;
    }
    const [oldLine, newLine] = getLineNumbers(endRow);
    const lineChange = getLineChange(gutterCell(endRow, side));
    const lineCode = getLineCode({ id: diffFile.id, row: endRow, oldLine, newLine });
    const lines = getNewLineRangeContent(diffElement, lineRange, lineChange.position);
    store.commitLineRangeEditing({ lineChange, lineCode, lines });
  }

  function onDragStart(event) {
    const handle = event.target.closest('[data-line-range-handle]');
    if (!handle || !session) return;
    const type = handle.dataset.lineRangeHandle;
    handle.dataset.dragging = '';
    const { dataTransfer } = event;
    if (dataTransfer) {
      dataTransfer.effectAllowed = 'copy';
      dataTransfer.setData('text/plain', '');
    }
    session.diffFile.dataset.lineRangeDragging = '';
    const { lineRange } = session.editing;
    const anchorPos = type === 'start' ? lineRange.end : lineRange.start;
    const anchorRow = findLineRow(session.diffElement, anchorPos.old_line, anchorPos.new_line);
    session.drag = { anchorRow, rows: anchorRow.closest('table').rows };
    highlight();
  }

  function onDragOver(event) {
    if (!session?.drag) return;
    event.preventDefault();
    const { dataTransfer } = event;
    if (dataTransfer) dataTransfer.dropEffect = 'copy';

    const lineRange = getDragRange(session.diffFile, {
      ...session.drag,
      side: session.side,
      clientX: event.clientX,
      clientY: event.clientY,
    });
    if (!lineRange) return;
    session.editing.lineRange = lineRange;
    highlight();
  }

  function onDragEnd(event) {
    const handle = event.target.closest('[data-line-range-handle]');
    if (!session?.drag || !handle) return;
    delete handle.dataset.dragging;
    delete session.diffFile.dataset.lineRangeDragging;
    session.drag = null;
    commit();
  }

  function moveHandle(type, direction) {
    const { diffElement, side, editing } = session;
    const { lineRange } = editing;
    const anchorPos = type === 'start' ? lineRange.end : lineRange.start;
    const movingPos = type === 'start' ? lineRange.start : lineRange.end;
    const anchorRow = findLineRow(diffElement, anchorPos.old_line, anchorPos.new_line);
    const movingRow = findLineRow(diffElement, movingPos.old_line, movingPos.new_line);
    if (!anchorRow || !movingRow) return;
    const { rows } = anchorRow.closest('table');
    let idx = movingRow.rowIndex + direction;
    while (rows[idx]) {
      if (isRangeBoundary(rows[idx])) return;
      if (isCommentable(rows[idx], side)) break;
      idx += direction;
    }
    if (!rows[idx]) return;
    const crossesAnchor = type === 'start' ? idx > anchorRow.rowIndex : idx < anchorRow.rowIndex;
    editing.lineRange = getSelectionRange(rows, {
      startIdx: crossesAnchor ? idx : anchorRow.rowIndex,
      hoverIdx: idx,
      side,
    });
    highlight();
    const handle = session.handles[type];
    handle.style.transition = 'none';
    placeControls();
    handle.focus();
    requestAnimationFrame(() => {
      handle.style.transition = '';
    });
  }

  function onKeydown(event) {
    if (!session) return;

    if (event.key === 'Escape') {
      event.preventDefault();
      store.cancelLineRangeEditing();
      return;
    }

    const handle = event.target.closest('[data-line-range-handle]');
    if (!handle) return;

    if (event.key === 'Enter') {
      event.preventDefault();
      commit();
      return;
    }

    const type = handle.dataset.lineRangeHandle;
    switch (event.key) {
      case 'ArrowUp':
        moveHandle(type, -1);
        break;
      case 'ArrowDown':
        moveHandle(type, 1);
        break;
      case 'ArrowLeft':
        session.handles.start.focus();
        break;
      case 'ArrowRight':
        session.handles.end.focus();
        break;
      default:
        return;
    }
    event.preventDefault();
  }

  function onClick(event) {
    if (session && event.target.closest('[data-line-range-cancel]')) store.cancelLineRangeEditing();
  }

  function stopSession() {
    if (!session) return;
    const { diffFile, handles, cancelButton, instructions } = session;
    clearHandleRows();
    handles.start.remove();
    handles.end.remove();
    cancelButton.remove();
    instructions.remove();
    delete diffFile.dataset.lineRangeEditing;
    delete diffFile.dataset.lineRangeDragging;
    diffFile.trigger(CLEAR_HIGHLIGHT);
    session = null;
  }

  function startSession(editing) {
    if (session) stopSession();
    const { old_path: oldPath, new_path: newPath } = editing.discussion.position;
    const diffFile = findDiffFile({ oldPath, newPath });
    if (!diffFile?.diffElement) {
      store.cancelLineRangeEditing();
      return;
    }
    session = {
      editing,
      diffFile,
      diffElement: diffFile.diffElement,
      side: detectSide(diffFile.diffElement, editing),
      drag: null,
      handles: {
        start: createHandle('start'),
        end: createHandle('end'),
      },
      cancelButton: createCancelButton(),
      instructions: createInstructions(),
    };
    diffFile.dataset.lineRangeEditing = '';
    appElement.appendChild(session.instructions);
    if (!placeControls()) {
      stopSession();
      store.cancelLineRangeEditing();
      return;
    }
    highlight();
    session.handles.end.focus();
  }

  appElement.addEventListener('dragstart', onDragStart);
  appElement.addEventListener('dragend', onDragEnd);
  appElement.addEventListener('dragover', onDragOver);
  appElement.addEventListener('drop', (event) => {
    if (session?.drag) event.preventDefault();
  });
  appElement.addEventListener('keydown', onKeydown);
  appElement.addEventListener('click', onClick);

  watch(
    () => store.lineRangeEditing,
    (editing) => {
      if (editing) startSession(editing);
      else stopSession();
    },
  );
}
