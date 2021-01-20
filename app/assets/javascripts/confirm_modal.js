import Vue from 'vue';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

const mountConfirmModal = (optionalProps) =>
  new Vue({
    render(h) {
      return h(ConfirmModal, {
        props: {
          selector: '.js-confirm-modal-button',
          ...optionalProps,
        },
      });
    },
  }).$mount();

export default (optionalProps = {}) => mountConfirmModal(optionalProps);
