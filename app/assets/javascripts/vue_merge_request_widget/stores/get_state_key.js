import { stateKey } from './state_maps';

export default function deviseState() {
  if (!this.commitsCount) {
    return stateKey.nothingToMerge;
  } else if (this.projectArchived) {
    return stateKey.archived;
  } else if (this.branchMissing) {
    return stateKey.missingBranch;
  } else if (this.mergeStatus === 'unchecked' || this.mergeStatus === 'checking') {
    return stateKey.checking;
  } else if (this.hasConflicts) {
    return stateKey.conflicts;
  } else if (this.shouldBeRebased) {
    return stateKey.rebase;
  } else if (this.hasMergeChecksFailed && !this.autoMergeEnabled) {
    return stateKey.mergeChecksFailed;
  } else if (this.onlyAllowMergeIfPipelineSucceeds && this.isPipelineFailed) {
    return stateKey.pipelineFailed;
  } else if (this.draft) {
    return stateKey.draft;
  } else if (this.hasMergeableDiscussionsState && !this.autoMergeEnabled) {
    return stateKey.unresolvedDiscussions;
  } else if (this.isPipelineBlocked) {
    return stateKey.pipelineBlocked;
  } else if (this.canMerge && this.isSHAMismatch) {
    return stateKey.shaMismatch;
  } else if (this.autoMergeEnabled && !this.mergeError) {
    return stateKey.autoMergeEnabled;
  } else if (this.canBeMerged) {
    return stateKey.readyToMerge;
  }
  return null;
}
