import Vue from 'vue';
import DeleteTagModal from '~/tags/components/delete_tag_modal.vue';

export default function initDeleteTagModal() {
  const el = document.querySelector('.js-delete-tag-modal');
  if (!el) return false;

  return new Vue({
    el,
    name: 'DeleteTagModalRoot',
    render(createComponent) {
      return createComponent(DeleteTagModal);
    },
  });
}
