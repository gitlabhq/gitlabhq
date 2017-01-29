/* eslint-disable no-new, no-param-reassign */
/* global Vue, CommitsPipelineStore, PipelinesService, Flash */

//= require vue
//= require_tree .

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

  gl.commits.pipelines.PipelinesTableBundle = new gl.commits.pipelines.PipelinesTableView({
    el: document.querySelector('#commit-pipeline-table-view'),
  });
});
