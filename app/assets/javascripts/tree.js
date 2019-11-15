/* eslint-disable func-names, consistent-return, one-var, no-else-return, class-methods-use-this */

import $ from 'jquery';
import { visitUrl } from './lib/utils/url_utility';

export default class TreeView {
  constructor() {
    this.initKeyNav();
    // Code browser tree slider
    // Make the entire tree-item row clickable, but not if clicking another link (like a commit message)
    $('.tree-content-holder .tree-item').on('click', function(e) {
      const $clickedEl = $(e.target);
      const path = $('.tree-item-file-name a', this).attr('href');
      if (!$clickedEl.is('a') && !$clickedEl.is('.str-truncated')) {
        if (e.metaKey || e.which === 2) {
          e.preventDefault();
          return window.open(path, '_blank');
        } else {
          return visitUrl(path);
        }
      }
    });
    // Show the "Loading commit data" for only the first element
    $('span.log_loading:first').removeClass('hide');
  }

  initKeyNav() {
    const li = $('tr.tree-item');
    let liSelected = null;
    return $('body').keydown(e => {
      let next, path;
      if ($('input:focus').length > 0 && (e.which === 38 || e.which === 40)) {
        return false;
      }
      if (e.which === 40) {
        if (liSelected) {
          next = liSelected.next();
          if (next.length > 0) {
            liSelected.removeClass('selected');
            liSelected = next.addClass('selected');
          }
        } else {
          liSelected = li.eq(0).addClass('selected');
        }
        return $(liSelected).focus();
      } else if (e.which === 38) {
        if (liSelected) {
          next = liSelected.prev();
          if (next.length > 0) {
            liSelected.removeClass('selected');
            liSelected = next.addClass('selected');
          }
        } else {
          liSelected = li.last().addClass('selected');
        }
        return $(liSelected).focus();
      } else if (e.which === 13) {
        path = $('.tree-item.selected .tree-item-file-name a').attr('href');
        if (path) {
          return visitUrl(path);
        }
      }
    });
  }
}
