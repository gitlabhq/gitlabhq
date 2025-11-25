import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { pinia } from '~/pinia/instance';

export function initNewDiscussionToggle(appElement) {
  const toggle = appElement.querySelector('[data-new-discussion-toggle]');

  if (!toggle) return;

  let hideTimerId;
  let lastFocusedElement;

  function isValidTarget(element) {
    return element.closest('[data-hunk-lines]') && !element.closest('[data-change="meta"]');
  }

  function moveTo(target) {
    const row = target.closest('tr');
    if (row.querySelector('[data-position="old"]:first-child + [data-position="new"]')) {
      if (row.contains(toggle)) return;
      row.querySelector('[data-position]').prepend(toggle);
      return;
    }
    const cell = target.closest('[data-position]');
    if (!cell || toggle.parentElement === cell) return;
    const matchingCell = row.querySelector(`[data-position="${cell.dataset.position}"]`);
    if (!matchingCell.querySelector('[data-line-number]')) {
      toggle.hidden = true;
      return;
    }
    matchingCell.prepend(toggle);
  }

  function onEnter(event) {
    if (!isValidTarget(event.target)) return;
    if (event instanceof FocusEvent) lastFocusedElement = event.target;
    clearTimeout(hideTimerId);
    toggle.hidden = false;
    moveTo(event.target);
  }

  function onLeave(event) {
    if (!isValidTarget(event.target)) return;
    if (event instanceof FocusEvent) lastFocusedElement = undefined;
    clearTimeout(hideTimerId);
    hideTimerId = setTimeout(() => {
      if (lastFocusedElement && lastFocusedElement !== toggle) {
        toggle.hidden = false;
        moveTo(lastFocusedElement);
      } else {
        toggle.hidden = true;
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
  });
}
