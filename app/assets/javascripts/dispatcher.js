/* eslint-disable consistent-return, no-new */

import $ from 'jquery';
import GfmAutoComplete from './gfm_auto_complete';
import { convertPermissionToBoolean } from './lib/utils/common_utils';

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

export default () => {
  const page = $('body').attr('data-page');
  if (page) {
    initGFMInput();
  }
};
