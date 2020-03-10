import Vue from 'vue';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

const mountConfirmModal = () => {
  return new Vue({
    render(h) {
      return h(ConfirmModal, {
        props: { selector: '.js-confirm-modal-button' },
      });
    },
  }).$mount();
};

export default () => mountConfirmModal();
