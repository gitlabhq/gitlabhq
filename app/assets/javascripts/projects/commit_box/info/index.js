import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import { initCommitPipelineMiniGraph } from './init_commit_pipeline_mini_graph';
import { loadBranches } from './load_branches';
import initCommitPipelineStatus from './init_commit_pipeline_status';

export const initCommitBoxInfo = () => {
  // Display commit related branches
  loadBranches();

  // Related merge requests to this commit
  fetchCommitMergeRequests();

  // Display pipeline mini graph for this commit
  initCommitPipelineMiniGraph();

  initCommitPipelineStatus();
};
