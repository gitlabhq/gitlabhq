import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { pinia } from '~/pinia/instance';
import { moveToggle } from '~/rapid_diffs/utils/new_discussion_toggle';

export function initNewDiscussionToggle(appElement, { allowExpandedLines = false } = {}) {
  const toggle = appElement.querySelector('[data-new-discussion-toggle]');

  if (!toggle) return;

  let hideTimerId;
  let lastFocusedElement;
  let currentDiffFile;

  function isValidTarget(element) {
    const row = element.closest('[data-hunk-lines]');
    if (!row || !row.querySelector('[data-line-number]')) return false;
    if (element.closest('[data-change="meta"]')) return false;
    return allowExpandedLines || !element.closest('[data-expanded]');
  }

  function hasGutterToggle(row, cellIndex) {
    const discussionRow = row.nextElementSibling;
    if (discussionRow?.dataset.discussionRow !== 'true') return false;
    const cell = discussionRow.children[Math.min(cellIndex, discussionRow.children.length - 1)];
    return cell?.querySelector('[data-gutter-toggle]') !== null;
  }

  function markDiffFile(row) {
    const diffFile = row.closest('diff-file');
    if (currentDiffFile && currentDiffFile !== diffFile) {
      delete currentDiffFile.dataset.withDiscussionToggle;
    }
    currentDiffFile = diffFile;
    if (diffFile) diffFile.dataset.withDiscussionToggle = '';
  }

  function hideToggle() {
    toggle.hidden = true;
    if (currentDiffFile) {
      delete currentDiffFile.dataset.withDiscussionToggle;
      currentDiffFile = null;
    }
  }

  function getLineNumber(row, side) {
    const el = row.querySelector(`[data-position="${side}"] [data-line-number]`);
    return el ? Number(el.dataset.lineNumber) : null;
  }

  function setTogglePosition(row) {
    const { change } = toggle.parentElement.dataset;
    const oldLine = change === 'added' ? null : getLineNumber(row, 'old');
    const newLine = change === 'removed' ? null : getLineNumber(row, 'new');
    const position = { old_line: oldLine, new_line: newLine, type: null };
    toggle.lineRange = { start: position, end: position };
  }

  function moveTo(target) {
    const row = target.closest('tr');
    markDiffFile(row);
    if (row.querySelector('[data-position="old"]:first-child + [data-position="new"]')) {
      if (hasGutterToggle(row, 0)) {
        hideToggle();
        return;
      }
      if (row.contains(toggle)) return;
      moveToggle(toggle, row);
      setTogglePosition(row);
      return;
    }
    const cell = target.closest('[data-position]');
    if (!cell || toggle.parentElement === cell) return;
    const matchingCell = row.querySelector(`[data-position="${cell.dataset.position}"]`);
    if (!matchingCell.querySelector('[data-line-number]')) {
      hideToggle();
      return;
    }
    const cellIndex = cell.dataset.position === 'old' ? 0 : 1;
    if (hasGutterToggle(row, cellIndex)) {
      hideToggle();
      return;
    }
    moveToggle(toggle, row, cell.dataset.position);
    setTogglePosition(row);
  }

  function onEnter(event) {
    if (toggle.dataset.dragging != null) return;
    if (!isValidTarget(event.target)) return;
    if (event instanceof FocusEvent) lastFocusedElement = event.target;
    clearTimeout(hideTimerId);
    toggle.hidden = false;
    moveTo(event.target);
  }

  function onLeave(event) {
    if (toggle.dataset.dragging != null) return;
    if (!isValidTarget(event.target)) return;
    if (event instanceof FocusEvent) lastFocusedElement = undefined;
    clearTimeout(hideTimerId);
    hideTimerId = setTimeout(() => {
      if (lastFocusedElement && lastFocusedElement !== toggle) {
        toggle.hidden = false;
        moveTo(lastFocusedElement);
      } else {
        hideToggle();
      }
    });
  }

  appElement.addEventListener('mouseover', onEnter);
  appElement.addEventListener('mouseout', onLeave);
  appElement.addEventListener('focusin', onEnter);
  appElement.addEventListener('focusout', onLeave);

  useDiffsList(pinia).$onAction(({ name }) => {
    if (name !== 'reloadDiffs') return;
    // reload removes all elements in the list, we need to detach the button before it gets removed
    const diffsList = appElement.querySelector('[data-diffs-list]');
    diffsList.parentElement.prepend(toggle);
    currentDiffFile = null;
  });
}
