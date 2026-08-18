import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CommitPipelinesList from '~/ci/commit/components/commit_pipelines_list.vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { initPipelineCountListener } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

/**
 * Used in:
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 */
export const initCommitPipelines = () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    initPipelineCountListener(pipelineTableViewEl);

    // The app mounts on a child element so that pipelineTableViewEl stays in the
    // document: the listener above receives the `update-pipelines-count` event
    // that the app bubbles up to it.
    const el = document.createElement('div');
    pipelineTableViewEl.appendChild(el);

    initVueApp({
      el,
      name: 'CommitPipelinesListRoot',
      component: CommitPipelinesList,
      apolloProvider,
      props: {
        projectFullPath: pipelineTableViewEl.dataset.projectFullPath,
        commitSha: pipelineTableViewEl.dataset.commitSha,
      },
    });
  }
};
