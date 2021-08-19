import Vue from 'vue';
import RollbackModalManager from './components/rollback_modal_manager.vue';

const mountConfirmRollbackModal = (optionalProps) =>
  new Vue({
    render(h) {
      return h(RollbackModalManager, {
        props: {
          selector: '.js-confirm-rollback-modal-button',
          ...optionalProps,
        },
      });
    },
  }).$mount();

export default (optionalProps = {}) => mountConfirmRollbackModal(optionalProps);
