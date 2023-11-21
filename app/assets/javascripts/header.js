// TODO: Remove this with the removal of the old navigation.
// See https://gitlab.com/groups/gitlab-org/-/epics/11875.

import { highCountTrim } from '~/lib/utils/text_utility';
import Tracking from '~/tracking';

/**
 * Updates todo counter when todos are toggled.
 * When count is 0, we hide the badge.
 *
 * @param {jQuery.Event} e
 * @param {String} count
 */
export default function initTodoToggle() {
  document.addEventListener('todo:toggle', (e) => {
    const updatedCount = e.detail.count || 0;
    const todoPendingCount = document.querySelector('.js-todos-count');

    if (todoPendingCount) {
      todoPendingCount.textContent = highCountTrim(updatedCount);
      if (updatedCount === 0) {
        todoPendingCount.classList.add('hidden');
      } else {
        todoPendingCount.classList.remove('hidden');
      }
    }
  });
}

function trackShowUserDropdownLink(trackEvent, elToTrack, el) {
  const { trackLabel, trackProperty } = elToTrack.dataset;

  el.addEventListener('shown.bs.dropdown', () => {
    Tracking.event(document.body.dataset.page, trackEvent, {
      label: trackLabel,
      property: trackProperty,
    });
  });
}

export function initNavUserDropdownTracking() {
  const el = document.querySelector('.js-nav-user-dropdown');
  const buyEl = document.querySelector('.js-buy-pipeline-minutes-link');

  if (el && buyEl) {
    trackShowUserDropdownLink('show_buy_ci_minutes', buyEl, el);
  }
}

requestIdleCallback(initNavUserDropdownTracking);
