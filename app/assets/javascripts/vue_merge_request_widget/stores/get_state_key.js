import { DETAILED_MERGE_STATUS } from '../constants';
import { stateKey } from './state_maps';

export default function deviseState() {
  if (!this.commitsCount) {
    return stateKey.nothingToMerge;
  } else if (this.projectArchived) {
    return stateKey.archived;
  } else if (this.branchMissing) {
    return stateKey.missingBranch;
  } else if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.CHECKING) {
    return stateKey.checking;
  } else if (this.hasConflicts) {
    return stateKey.conflicts;
  } else if (this.shouldBeRebased) {
    return stateKey.rebase;
  } else if (this.hasMergeChecksFailed && !this.autoMergeEnabled) {
    return stateKey.mergeChecksFailed;
  } else if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_MUST_PASS) {
    return stateKey.pipelineFailed;
  } else if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.DRAFT_STATUS) {
    return stateKey.draft;
  } else if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.DISCUSSIONS_NOT_RESOLVED) {
    return stateKey.unresolvedDiscussions;
  } else if (this.canMerge && this.isSHAMismatch) {
    return stateKey.shaMismatch;
  } else if (this.autoMergeEnabled && !this.mergeError) {
    return stateKey.autoMergeEnabled;
  } else if (
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.MERGEABLE ||
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_STILL_RUNNING
  ) {
    return stateKey.readyToMerge;
  }
  return stateKey.checking;
}
