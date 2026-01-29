import Vue from 'vue';
import DeleteBranchModal from '~/branches/components/delete_branch_modal.vue';

export default function initDeleteBranchModal() {
  const el = document.querySelector('.js-delete-branch-modal');
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'DeleteBranchModalRoot',
    render(createComponent) {
      return createComponent(DeleteBranchModal);
    },
  });
}
