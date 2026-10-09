import $ from 'jquery';
import { parseBoolean } from '@gitlab/frontend-utils';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';

export default function initGFMInput($els) {
  $els.each((i, el) => {
    const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
    const enableGFM = parseBoolean(el.dataset.supportsAutocomplete);

    gfm.setup($(el), {
      emojis: true,
      members: enableGFM,
      issues: enableGFM,
      issuesAlternative: enableGFM,
      workItems: enableGFM,
      iterations: enableGFM,
      milestones: enableGFM,
      mergeRequests: enableGFM,
      labels: enableGFM,
      vulnerabilities: enableGFM,
      statuses: enableGFM,
    });
  });
}
