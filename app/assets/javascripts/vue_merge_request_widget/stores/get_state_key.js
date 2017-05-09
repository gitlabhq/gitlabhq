export default function deviseState(data) {
  if (data.project_archived) {
    return 'archived';
  } else if (data.branch_missing) {
    return 'missingBranch';
  } else if (!data.commits_count) {
    return 'nothingToMerge';
  } else if (this.mergeStatus === 'unchecked') {
    return 'checking';
  } else if (data.has_conflicts) {
    return 'conflicts';
  } else if (data.work_in_progress) {
    return 'workInProgress';
  } else if (this.mergeWhenPipelineSucceeds) {
    return this.mergeError ? 'autoMergeFailed' : 'mergeWhenPipelineSucceeds';
  } else if (!this.canMerge) {
    return 'notAllowedToMerge';
  } else if (this.onlyAllowMergeIfPipelineSucceeds && this.isPipelineFailed) {
    return 'pipelineFailed';
  } else if (this.hasMergeableDiscussionsState) {
    return 'unresolvedDiscussions';
  } else if (this.isPipelineBlocked) {
    return 'pipelineBlocked';
  } else if (this.canBeMerged) {
    return 'readyToMerge';
  }
  return null;
}
