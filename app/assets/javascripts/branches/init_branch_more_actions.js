import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el,
    name: 'DeleteBranchButtonRoot',
    component: DeleteBranchButton,
    props: {
      branchName,
      defaultBranchName,
      canDeleteBranch: parseBoolean(canDeleteBranch),
      isProtectedBranch: parseBoolean(isProtectedBranch),
      merged: parseBoolean(merged),
      comparePath,
      deletePath,
    },
  });
}
