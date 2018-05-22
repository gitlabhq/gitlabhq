import { stateKey } from './state_maps';

export default function deviseState(data) {
  if (data.project_archived) {
    return stateKey.archived;
  } else if (data.branch_missing) {
    return stateKey.missingBranch;
  } else if (!data.commits_count) {
    return stateKey.nothingToMerge;
  } else if (this.mergeStatus === 'unchecked') {
    return stateKey.checking;
  } else if (data.has_conflicts) {
    return stateKey.conflicts;
  } else if (data.work_in_progress) {
    return stateKey.workInProgress;
  } else if (this.onlyAllowMergeIfPipelineSucceeds && this.isPipelineFailed) {
    return stateKey.pipelineFailed;
  } else if (this.hasMergeableDiscussionsState) {
    return stateKey.unresolvedDiscussions;
  } else if (this.isPipelineBlocked) {
    return stateKey.pipelineBlocked;
  } else if (this.hasSHAChanged) {
    return stateKey.shaMismatch;
  } else if (this.mergeWhenPipelineSucceeds) {
    return this.mergeError ? stateKey.autoMergeFailed : stateKey.mergeWhenPipelineSucceeds;
  } else if (!this.canMerge) {
    return stateKey.notAllowedToMerge;
  } else if (this.shouldBeRebased) {
    return stateKey.rebase;
  } else if (this.canBeMerged) {
    return stateKey.readyToMerge;
  }
  return null;
}
