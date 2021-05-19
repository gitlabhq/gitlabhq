import { BRANCH_SUFFIX_COUNT } from '../constants';

const generateBranchSuffix = () => `${Date.now()}`.substr(BRANCH_SUFFIX_COUNT);

const generateBranchName = (username, targetBranch) =>
  `${username}-${targetBranch}-patch-${generateBranchSuffix()}`;

export default generateBranchName;
