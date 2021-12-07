import Vue from 'vue';
import DeleteLabelModal from '~/vue_shared/components/delete_label_modal.vue';

const mountDeleteLabelModal = (optionalProps) =>
  new Vue({
    render(h) {
      return h(DeleteLabelModal, {
        props: {
          selector: '.js-delete-label-modal-button',
          ...optionalProps,
        },
      });
    },
  }).$mount();

export default (optionalProps = {}) => mountDeleteLabelModal(optionalProps);
