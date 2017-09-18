import Vue from 'vue';
import commitPipelinesTable from './pipelines_table.vue';

/**
 * Used in:
 *  - Commit details View > Pipelines Tab > Pipelines Table.
 *  - Merge Request details View > Pipelines Tab > Pipelines Table.
 *  - New Merge Request View > Pipelines Tab > Pipelines Table.
 */

const CommitPipelinesTable = Vue.extend(commitPipelinesTable);

// export for use in merge_request_tabs.js (TODO: remove this hack when we understand how to load
// vue.js in merge_request_tabs.js)
window.gl = window.gl || {};
window.gl.CommitPipelinesTable = CommitPipelinesTable;

document.addEventListener('DOMContentLoaded', () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
      // Update MR and Commits tabs
    pipelineTableViewEl.addEventListener('update-pipelines-count', (event) => {
      if (event.detail.pipelines &&
        event.detail.pipelines.count &&
        event.detail.pipelines.count.all) {
        const badge = document.querySelector('.js-pipelines-mr-count');

        badge.textContent = event.detail.pipelines.count.all;
      }
    });

    if (pipelineTableViewEl.dataset.disableInitialization === undefined) {
      const hasCiEnabled = (pipelineTableViewEl.dataset.hasCi !== undefined);
      const canCreatePipeline = gl.utils.convertPermissionToBoolean(pipelineTableViewEl.dataset.canCreatePipeline);
      const newPipelinePath = String(pipelineTableViewEl.dataset.newPipelinePath);
      const table = new CommitPipelinesTable({
        propsData: {
          endpoint: pipelineTableViewEl.dataset.endpoint,
          newPipelinePath: newPipelinePath,
          hasCiEnabled: hasCiEnabled,
          helpPagePath: pipelineTableViewEl.dataset.helpPagePath,
          canCreatePipeline: canCreatePipeline,
          autoDevopsHelpPath: pipelineTableViewEl.dataset.helpAutoDevopsPath,
        },
      }).$mount();
      pipelineTableViewEl.appendChild(table.$el);
    }
  }
});
