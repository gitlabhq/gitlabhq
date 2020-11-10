import { loadBranches } from './load_branches';
import { initDetailsButton } from './init_details_button';
import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';

export const initCommitBoxInfo = (containerSelector = '.js-commit-box-info') => {
  const containerEl = document.querySelector(containerSelector);

  // Display commit related branches
  loadBranches(containerEl);

  // Related merge requests to this commit
  fetchCommitMergeRequests();

  // Display pipeline info for this commit
  new MiniPipelineGraph({
    container: '.js-commit-pipeline-graph',
  }).bindEvents();

  initDetailsButton();
};
