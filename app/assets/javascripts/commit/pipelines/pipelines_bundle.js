import Vue from 'vue';
import commitPipelinesTable from './pipelines_table.vue';

/**
 * Used in:
 *  - Project Pipelines List (projects:pipelines:index)
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 *  - Merge Request details View > Pipelines Tab > Pipelines Table (projects:merge_requests:show)
 *  - New Merge Request View > Pipelines Tab > Pipelines Table (projects:merge_requests:creations:new)
 */

const CommitPipelinesTable = Vue.extend(commitPipelinesTable);

// export for use in merge_request_tabs.js (TODO: remove this hack when we understand how to load
// vue.js in merge_request_tabs.js)
window.gl = window.gl || {};
window.gl.CommitPipelinesTable = CommitPipelinesTable;

export default () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    pipelineTableViewEl.addEventListener('update-pipelines-count', event => {
      if (
        event.detail.pipelines &&
        event.detail.pipelines.count &&
        event.detail.pipelines.count.all
      ) {
        const badge = document.querySelector('.js-pipelines-mr-count');

        badge.textContent = event.detail.pipelines.count.all;
      }
    });

    if (pipelineTableViewEl.dataset.disableInitialization === undefined) {
      const table = new CommitPipelinesTable({
        propsData: {
          endpoint: pipelineTableViewEl.dataset.endpoint,
          helpPagePath: pipelineTableViewEl.dataset.helpPagePath,
          emptyStateSvgPath: pipelineTableViewEl.dataset.emptyStateSvgPath,
          errorStateSvgPath: pipelineTableViewEl.dataset.errorStateSvgPath,
          autoDevopsHelpPath: pipelineTableViewEl.dataset.helpAutoDevopsPath,
        },
      }).$mount();
      pipelineTableViewEl.appendChild(table.$el);
    }
  }
};
