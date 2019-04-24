import $ from 'jquery';
import { parseBoolean } from '~/lib/utils/common_utils';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';

export default function initGFMInput() {
  $('.js-gfm-input:not(.js-vue-textarea)').each((i, el) => {
    const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
    const enableGFM = parseBoolean(el.dataset.supportsAutocomplete);

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
