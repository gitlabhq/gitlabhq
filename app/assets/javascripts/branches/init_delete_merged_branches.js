import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DeleteMergedBranches from '~/branches/components/delete_merged_branches.vue';

export default function initDeleteMergedBranchesModal() {
  const el = document.querySelector('.js-delete-merged-branches');
  if (!el) {
    return false;
  }

  const { formPath, defaultBranch } = el.dataset;

  return initVueApp({
    el,
    name: 'DeleteMergedBranchesRoot',
    component: DeleteMergedBranches,
    props: {
      formPath,
      defaultBranch,
    },
  });
}
