import Vue from 'vue';
import NamespaceSelect from '~/namespace_select';
import ProjectsList from '~/projects_list';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';

function mountRemoveMemberModal() {
  const el = document.querySelector('.js-remove-member-modal');
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(RemoveMemberModal);
    },
  });
}

mountRemoveMemberModal();

new ProjectsList(); // eslint-disable-line no-new

document
  .querySelectorAll('.js-namespace-select')
  .forEach((dropdown) => new NamespaceSelect({ dropdown }));
