/* global DocumentTouch */

import $ from 'jquery';
import sortableConfig from 'ee_else_ce/sortable/sortable_config';

export function sortableStart() {
  $('.has-tooltip')
    .tooltip('hide')
    .tooltip('disable');
  document.body.classList.add('is-dragging');
}

export function sortableEnd() {
  $('.has-tooltip').tooltip('enable');
  document.body.classList.remove('is-dragging');
}

export function getBoardSortableDefaultOptions(obj) {
  const touchEnabled =
    'ontouchstart' in window || (window.DocumentTouch && document instanceof DocumentTouch);

  const defaultSortOptions = Object.assign({}, sortableConfig, {
    filter: '.board-delete, .btn',
    delay: touchEnabled ? 100 : 0,
    scrollSensitivity: touchEnabled ? 60 : 100,
    scrollSpeed: 20,
    onStart: sortableStart,
    onEnd: sortableEnd,
  });

  Object.keys(obj).forEach(key => {
    defaultSortOptions[key] = obj[key];
  });
  return defaultSortOptions;
}
