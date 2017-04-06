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

$(() => {
  window.gl = window.gl || {};
  gl.commits = gl.commits || {};
  gl.commits.pipelines = gl.commits.pipelines || {};

  if (gl.commits.PipelinesTableBundle) {
    document.querySelector('#commit-pipeline-table-view').removeChild(this.pipelinesTableBundle.$el);
    gl.commits.PipelinesTableBundle.$destroy(true);
  }

  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl && pipelineTableViewEl.dataset.disableInitialization === undefined) {
    gl.commits.pipelines.PipelinesTableBundle = new CommitPipelinesTable().$mount();
    document.querySelector('#commit-pipeline-table-view').appendChild(gl.commits.pipelines.PipelinesTableBundle.$el);
  }
});
