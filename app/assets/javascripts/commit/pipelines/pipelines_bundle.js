/* eslint-disable no-new, no-param-reassign */
/* global Vue, CommitsPipelineStore, PipelinesService, Flash */

window.Vue = require('vue');
require('./pipelines_table');
/**
 * Commits View > Pipelines Tab > Pipelines Table.
 * Merge Request View > Pipelines Tab > Pipelines Table.
 *
 * Renders Pipelines table in pipelines tab in the commits show view.
 * Renders Pipelines table in pipelines tab in the merge request show view.
 */

$(() => {
  window.gl = window.gl || {};
  gl.commits = gl.commits || {};
  gl.commits.pipelines = gl.commits.pipelines || {};

  if (gl.commits.PipelinesTableBundle) {
    gl.commits.PipelinesTableBundle.$destroy(true);
  }

  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');
  gl.commits.pipelines.PipelinesTableBundle = new gl.commits.pipelines.PipelinesTableView();

  if (pipelineTableViewEl && pipelineTableViewEl.dataset.disableInitialization === undefined) {
    gl.commits.pipelines.PipelinesTableBundle.$mount(pipelineTableViewEl);
  }
});
