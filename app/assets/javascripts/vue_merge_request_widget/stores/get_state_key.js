import { DETAILED_MERGE_STATUS, MWCP_MERGE_STRATEGY } from '../constants';
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
  if (this.canMerge && this.isSHAMismatch) {
    return stateKey.shaMismatch;
  }
  if (
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.MERGEABLE ||
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.CI_STILL_RUNNING ||
    (!this.autoMergeEnabled && this.preferredAutoMergeStrategy === MWCP_MERGE_STRATEGY)
  ) {
    return stateKey.readyToMerge;
  }
  return null;
}
