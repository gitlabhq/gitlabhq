/* eslint-disable consistent-return, no-new */

import $ from 'jquery';
import GfmAutoComplete from './gfm_auto_complete';
import { convertPermissionToBoolean } from './lib/utils/common_utils';
import Shortcuts from './shortcuts';
import performanceBar from './performance_bar';

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
    performanceBar({ container: '#js-peek' });
  }
}

export default () => {
  const page = $('body').attr('data-page');
  if (page) {
    initPageShortcuts(page);
    initGFMInput();
    initPerformanceBar();
  }
};
