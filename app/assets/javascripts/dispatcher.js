/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */

import $ from 'jquery';
import Flash from './flash';
import GfmAutoComplete from './gfm_auto_complete';
import { convertPermissionToBoolean } from './lib/utils/common_utils';
import GlFieldErrors from './gl_field_errors';
import Shortcuts from './shortcuts';
import SearchAutocomplete from './search_autocomplete';

function initSearch() {
  // Only when search form is present
  if ($('.search').length) {
    return new SearchAutocomplete();
  }
}

function initFieldErrors() {
  $('.gl-show-field-errors').each((i, form) => {
    new GlFieldErrors(form);
  });
}

function initPageShortcuts(page) {
  const pagesWithCustomShortcuts = [
    'projects:activity',
    'projects:artifacts:browse',
    'projects:artifacts:file',
    'projects:blame:show',
    'projects:blob:show',
    'projects:commit:show',
    'projects:commits:show',
    'projects:find_file:show',
    'projects:issues:edit',
    'projects:issues:index',
    'projects:issues:new',
    'projects:issues:show',
    'projects:merge_requests:creations:diffs',
    'projects:merge_requests:creations:new',
    'projects:merge_requests:edit',
    'projects:merge_requests:index',
    'projects:merge_requests:show',
    'projects:network:show',
    'projects:show',
    'projects:tree:show',
    'groups:show',
  ];

  if (pagesWithCustomShortcuts.indexOf(page) === -1) {
    new Shortcuts();
  }
}

function initGFMInput() {
  $('.js-gfm-input:not(.js-vue-textarea)').each((i, el) => {
    const gfm = new GfmAutoComplete(
      gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources,
    );
    const enableGFM = convertPermissionToBoolean(
      el.dataset.supportsAutocomplete,
    );
    gfm.setup($(el), {
      emojis: true,
      members: enableGFM,
      issues: enableGFM,
      milestones: enableGFM,
      mergeRequests: enableGFM,
      labels: enableGFM,
    });
  });
}

function initPerformanceBar() {
  if (document.querySelector('#js-peek')) {
    import('./performance_bar')
      .then(m => new m.default({ container: '#js-peek' })) // eslint-disable-line new-cap
      .catch(() => Flash('Error loading performance bar module'));
  }
}

export default () => {
  initSearch();
  initFieldErrors();

  const page = $('body').attr('data-page');
  if (page) {
    initPageShortcuts(page);
    initGFMInput();
    initPerformanceBar();
  }
};
