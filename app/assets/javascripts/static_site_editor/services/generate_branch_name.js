import { BRANCH_SUFFIX_COUNT, DEFAULT_TARGET_BRANCH } from '../constants';

const generateBranchSuffix = () => `${Date.now()}`.substr(BRANCH_SUFFIX_COUNT);

const generateBranchName = (username, targetBranch = DEFAULT_TARGET_BRANCH) =>
  `${username}-${targetBranch}-patch-${generateBranchSuffix()}`;

export default generateBranchName;
