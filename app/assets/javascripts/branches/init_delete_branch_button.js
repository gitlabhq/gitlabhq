import Vue from 'vue';
import DeleteBranchButton from '~/branches/components/delete_branch_button.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function initDeleteBranchButton(el) {
  if (!el) {
    return false;
  }

  const {
    branchName,
    defaultBranchName,
    deletePath,
    tooltip,
    disabled,
    isProtectedBranch,
    merged,
  } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(DeleteBranchButton, {
        props: {
          branchName,
          defaultBranchName,
          deletePath,
          tooltip,
          disabled: parseBoolean(disabled),
          isProtectedBranch: parseBoolean(isProtectedBranch),
          merged: parseBoolean(merged),
        },
      }),
  });
}
