/* global DocumentTouch */

import sortableConfig from '~/sortable/sortable_config';

export function sortableStart() {
  document.body.classList.add('is-dragging');
}

export function sortableEnd() {
  document.body.classList.remove('is-dragging');
}

export function getBoardSortableDefaultOptions(obj) {
  const touchEnabled =
    'ontouchstart' in window || (window.DocumentTouch && document instanceof DocumentTouch);

  const defaultSortOptions = {
    ...sortableConfig,
    filter: '.no-drag',
    delay: touchEnabled ? 100 : 0,
    scrollSensitivity: touchEnabled ? 60 : 100,
    scrollSpeed: 20,
    onStart: sortableStart,
    onEnd: sortableEnd,
  };

  Object.keys(obj).forEach((key) => {
    defaultSortOptions[key] = obj[key];
  });
  return defaultSortOptions;
}
