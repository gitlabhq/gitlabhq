import Vue from 'vue';
import DeleteBranchButton from '~/branches/components/branch_more_actions.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function initBranchMoreActions(el) {
  if (!el) {
    return false;
  }

  const {
    branchName,
    defaultBranchName,
    canDeleteBranch,
    isProtectedBranch,
    merged,
    comparePath,
    deletePath,
  } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(DeleteBranchButton, {
        props: {
          branchName,
          defaultBranchName,
          canDeleteBranch: parseBoolean(canDeleteBranch),
          isProtectedBranch: parseBoolean(isProtectedBranch),
          merged: parseBoolean(merged),
          comparePath,
          deletePath,
        },
      }),
  });
}
