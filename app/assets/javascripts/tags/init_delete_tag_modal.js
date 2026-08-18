import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DeleteTagModal from '~/tags/components/delete_tag_modal.vue';

export default function initDeleteTagModal() {
  const el = document.querySelector('.js-delete-tag-modal');
  if (!el) return false;

  return initVueApp({ el, name: 'DeleteTagModalRoot', component: DeleteTagModal });
}
