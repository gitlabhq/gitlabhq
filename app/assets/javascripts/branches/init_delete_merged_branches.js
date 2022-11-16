import Vue from 'vue';
import DeleteMergedBranches from '~/branches/components/delete_merged_branches.vue';

export default function initDeleteMergedBranchesModal() {
  const el = document.querySelector('.js-delete-merged-branches');
  if (!el) {
    return false;
  }

  const { formPath, defaultBranch } = el.dataset;

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(DeleteMergedBranches, {
        props: {
          formPath,
          defaultBranch,
        },
      });
    },
  });
}
