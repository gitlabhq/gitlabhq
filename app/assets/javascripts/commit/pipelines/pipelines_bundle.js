import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { initPipelineCountListener } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

/**
 * Used in:
 *  - Project Pipelines List (projects:pipelines)
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 *  - Merge request details View > Pipelines Tab > Pipelines Table (projects:merge_requests:show)
 *  - New merge request View > Pipelines Tab > Pipelines Table (projects:merge_requests:creations:new)
 */
export default () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    initPipelineCountListener(pipelineTableViewEl);

    if (pipelineTableViewEl.dataset.disableInitialization === undefined) {
      const table = new Vue({
        components: {
          CommitPipelinesTable: () =>
            import('~/commit/pipelines/legacy_pipelines_table_wrapper.vue'),
        },
        apolloProvider,
        provide: {
          artifactsEndpoint: pipelineTableViewEl.dataset.artifactsEndpoint,
          artifactsEndpointPlaceholder: pipelineTableViewEl.dataset.artifactsEndpointPlaceholder,
          fullPath: pipelineTableViewEl.dataset.fullPath,
          manualActionsLimit: 50,
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
