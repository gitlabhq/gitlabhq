/* eslint-disable no-param-reassign */

import Vue from 'vue';
import VueResource from 'vue-resource';
import CommitPipelinesTable from './pipelines_table';

Vue.use(VueResource);

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
  gl.commits.pipelines.PipelinesTableBundle = new CommitPipelinesTable();

  if (pipelineTableViewEl && pipelineTableViewEl.dataset.disableInitialization === undefined) {
    gl.commits.pipelines.PipelinesTableBundle.$mount(pipelineTableViewEl);
  }
});
