/* eslint-disable no-param-reassign */

import Vue from 'vue';
import VueResource from 'vue-resource';
import CommitPipelinesTable from './pipelines_table';

Vue.use(VueResource);

/**
 * Commits View > Pipelines Tab > Pipelines Table.
 *
 * Renders Pipelines table in pipelines tab in the commits show view.
 */

// export for use in merge_request_tabs.js (TODO: remove this hack)
window.gl = window.gl || {};
window.gl.CommitPipelinesTable = CommitPipelinesTable;

$(() => {
  gl.commits = gl.commits || {};
  gl.commits.pipelines = gl.commits.pipelines || {};

  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl && pipelineTableViewEl.dataset.disableInitialization === undefined) {
    gl.commits.pipelines.PipelinesTableBundle = new CommitPipelinesTable().$mount();
    pipelineTableViewEl.appendChild(gl.commits.pipelines.PipelinesTableBundle.$el);
  }
});
