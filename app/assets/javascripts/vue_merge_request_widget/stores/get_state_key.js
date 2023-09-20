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
    return stateKey.conflicts;
  }
  if (this.shouldBeRebased) {
    return stateKey.rebase;
  }
  if (this.hasMergeChecksFailed && !this.autoMergeEnabled) {
    return stateKey.mergeChecksFailed;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_MUST_PASS) {
    return stateKey.pipelineFailed;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.DRAFT_STATUS) {
    return stateKey.draft;
  }
  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.DISCUSSIONS_NOT_RESOLVED) {
    return stateKey.unresolvedDiscussions;
  }
  if (this.canMerge && this.isSHAMismatch) {
    return stateKey.shaMismatch;
  }
  if (this.autoMergeEnabled && !this.mergeError) {
    return stateKey.autoMergeEnabled;
  }
  if (
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.MERGEABLE ||
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_STILL_RUNNING
  ) {
    return stateKey.readyToMerge;
  }
  return stateKey.checking;
}
