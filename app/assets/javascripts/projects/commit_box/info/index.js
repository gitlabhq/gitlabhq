import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import initCommitPipelineSummary from './init_commit_pipeline_summary';
import initCommitReferences from './init_commit_references';

export const initCommitBoxInfo = () => {
  // Display commit related branches
  // Related merge requests to this commit
  fetchCommitMergeRequests();

  initCommitPipelineSummary();

  initCommitReferences();
};
