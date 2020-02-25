import Vue from 'vue';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

const mountConfirmModal = button => {
  const props = {
    path: button.dataset.path,
    method: button.dataset.method,
    modalAttributes: JSON.parse(button.dataset.modalAttributes),
  };

  return new Vue({
    render(h) {
      return h(ConfirmModal, { props });
    },
  }).$mount();
};

export default () => {
  document.getElementsByClassName('js-confirm-modal-button').forEach(button => {
    button.addEventListener('click', e => {
      e.preventDefault();

      mountConfirmModal(button);
    });
  });
};
