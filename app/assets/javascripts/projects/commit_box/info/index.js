import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import { initCommitPipelineMiniGraph } from './init_commit_pipeline_mini_graph';
import initCommitPipelineStatus from './init_commit_pipeline_status';
import initCommitReferences from './init_commit_references';

export const initCommitBoxInfo = () => {
  // Display commit related branches
  // Related merge requests to this commit
  fetchCommitMergeRequests();

  // Display pipeline mini graph for this commit
  initCommitPipelineMiniGraph();

  initCommitPipelineStatus();

  initCommitReferences();
};
