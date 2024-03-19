import { DETAILED_MERGE_STATUS } from '../constants';
import { stateKey } from './state_maps';

export default function deviseState() {
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.PREPARING) {
    return stateKey.preparing;
  }
  if (!this.commitsCount) {
    return stateKey.nothingToMerge;
  }
  if (this.projectArchived) {
    return stateKey.archived;
  }
  if (this.branchMissing) {
    return stateKey.missingBranch;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.CHECKING) {
    return stateKey.checking;
  }
  if (this.hasConflicts) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.conflicts;
  }
  if (this.shouldBeRebased) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.rebase;
  }
  if (this.hasMergeChecksFailed && !this.autoMergeEnabled) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.mergeChecksFailed;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_MUST_PASS) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.pipelineFailed;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.DRAFT_STATUS) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.draft;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.DISCUSSIONS_NOT_RESOLVED) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.unresolvedDiscussions;
  }
  if (this.canMerge && this.isSHAMismatch) {
    return stateKey.shaMismatch;
  }
  if (this.autoMergeEnabled && !this.mergeError) {
    return window.gon?.features?.mergeBlockedComponent ? null : stateKey.autoMergeEnabled;
  }
  if (
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.MERGEABLE ||
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_STILL_RUNNING
  ) {
    return stateKey.readyToMerge;
  }
  return window.gon?.features?.mergeBlockedComponent ? null : stateKey.checking;
}
