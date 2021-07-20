import Vue from 'vue';

/**
 * Used in:
 *  - Project Pipelines List (projects:pipelines:index)
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 *  - Merge request details View > Pipelines Tab > Pipelines Table (projects:merge_requests:show)
 *  - New merge request View > Pipelines Tab > Pipelines Table (projects:merge_requests:creations:new)
 */
export default () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    pipelineTableViewEl.addEventListener('update-pipelines-count', (event) => {
      if (event.detail.pipelineCount) {
        const badge = document.querySelector('.js-pipelines-mr-count');

        badge.textContent = event.detail.pipelineCount;
      }
    });

    if (pipelineTableViewEl.dataset.disableInitialization === undefined) {
      const table = new Vue({
        components: {
          CommitPipelinesTable: () => import('~/commit/pipelines/pipelines_table.vue'),
        },
        provide: {
          artifactsEndpoint: pipelineTableViewEl.dataset.artifactsEndpoint,
          artifactsEndpointPlaceholder: pipelineTableViewEl.dataset.artifactsEndpointPlaceholder,
        },
        render(createElement) {
          return createElement('commit-pipelines-table', {
            props: {
              endpoint: pipelineTableViewEl.dataset.endpoint,
              emptyStateSvgPath: pipelineTableViewEl.dataset.emptyStateSvgPath,
              errorStateSvgPath: pipelineTableViewEl.dataset.errorStateSvgPath,
            },
          });
        },
      }).$mount();
      pipelineTableViewEl.appendChild(table.$el);
    }
  }
};
