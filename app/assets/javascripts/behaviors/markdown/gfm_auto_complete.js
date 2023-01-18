import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function initGFMInput($els) {
  $els.each((i, el) => {
    const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
    const enableGFM = parseBoolean(el.dataset.supportsAutocomplete);

    gfm.setup($(el), {
      emojis: true,
      members: enableGFM,
      issues: enableGFM,
      iterations: enableGFM,
      milestones: enableGFM,
      mergeRequests: enableGFM,
      labels: enableGFM,
      vulnerabilities: enableGFM,
    });
  });
}
