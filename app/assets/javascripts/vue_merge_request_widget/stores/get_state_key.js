import { stateKey } from './state_maps';

export default function deviseState() {
  if (this.projectArchived) {
    return stateKey.archived;
  } else if (this.branchMissing) {
    return stateKey.missingBranch;
  } else if (!this.commitsCount) {
    return stateKey.nothingToMerge;
  } else if (this.mergeStatus === 'unchecked' || this.mergeStatus === 'checking') {
    return stateKey.checking;
  } else if (this.hasConflicts) {
    return stateKey.conflicts;
  } else if (this.shouldBeRebased) {
    return stateKey.rebase;
  } else if (this.onlyAllowMergeIfPipelineSucceeds && this.isPipelineFailed) {
    return stateKey.pipelineFailed;
  } else if (this.workInProgress) {
    return stateKey.workInProgress;
  } else if (this.hasMergeableDiscussionsState && !this.autoMergeEnabled) {
    return stateKey.unresolvedDiscussions;
  } else if (this.isPipelineBlocked) {
    return stateKey.pipelineBlocked;
  } else if (this.canMerge && this.isSHAMismatch) {
    return stateKey.shaMismatch;
  } else if (this.autoMergeEnabled) {
    return this.mergeError ? stateKey.autoMergeFailed : stateKey.autoMergeEnabled;
  } else if (!this.canMerge) {
    return stateKey.notAllowedToMerge;
  } else if (this.canBeMerged) {
    return stateKey.readyToMerge;
  }
  return null;
}
