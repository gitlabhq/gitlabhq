import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DeleteBranchModal from '~/branches/components/delete_branch_modal.vue';

export default function initDeleteBranchModal() {
  const el = document.querySelector('.js-delete-branch-modal');
  if (!el) {
    return false;
  }

  return initVueApp({ el, name: 'DeleteBranchModalRoot', component: DeleteBranchModal });
}
