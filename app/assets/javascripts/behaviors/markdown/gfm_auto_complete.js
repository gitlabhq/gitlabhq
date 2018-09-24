import $ from 'jquery';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import GfmAutoComplete from '~/gfm_auto_complete';

export default function initGFMInput() {
  $('.js-gfm-input:not(.js-vue-textarea)').each((i, el) => {
    const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
    const enableGFM = convertPermissionToBoolean(el.dataset.supportsAutocomplete);

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
