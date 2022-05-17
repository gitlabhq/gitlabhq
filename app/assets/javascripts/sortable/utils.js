/* global DocumentTouch */

import { defaultSortableOptions, DRAG_CLASS } from './constants';

export function sortableStart() {
  document.body.classList.add(DRAG_CLASS);
}

export function sortableEnd() {
  document.body.classList.remove(DRAG_CLASS);
}

export function isDragging() {
  return document.body.classList.contains(DRAG_CLASS);
}

export function getSortableDefaultOptions(options) {
  const touchEnabled =
    'ontouchstart' in window || (window.DocumentTouch && document instanceof DocumentTouch);

  const defaultSortOptions = {
    ...defaultSortableOptions,
    filter: '.no-drag',
    delay: touchEnabled ? 100 : 0,
    scrollSensitivity: touchEnabled ? 60 : 100,
    scrollSpeed: 20,
    onStart: sortableStart,
    onEnd: sortableEnd,
  };

  return {
    ...defaultSortOptions,
    ...options,
  };
}
