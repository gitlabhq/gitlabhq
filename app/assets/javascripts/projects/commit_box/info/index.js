import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';
import { initCommitPipelineMiniGraph } from './init_commit_pipeline_mini_graph';
import { initDetailsButton } from './init_details_button';
import { loadBranches } from './load_branches';

export const initCommitBoxInfo = (containerSelector = '.js-commit-box-info') => {
  const containerEl = document.querySelector(containerSelector);

  // Display commit related branches
  loadBranches(containerEl);

  // Related merge requests to this commit
  fetchCommitMergeRequests();

  // Display pipeline mini graph for this commit
  // Feature flag ci_commit_pipeline_mini_graph_vue
  if (gon.features.ciCommitPipelineMiniGraphVue) {
    initCommitPipelineMiniGraph();
  } else {
    new MiniPipelineGraph({
      container: '.js-commit-pipeline-graph',
    }).bindEvents();
  }

  initDetailsButton();
};
