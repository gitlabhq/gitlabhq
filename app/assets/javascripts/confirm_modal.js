import Vue from 'vue';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

const mountConfirmModal = () => {
  return new Vue({
    data() {
      return {
        path: '',
        method: '',
        modalAttributes: null,
        showModal: false,
      };
    },
    mounted() {
      document.querySelectorAll('.js-confirm-modal-button').forEach(button => {
        button.addEventListener('click', e => {
          e.preventDefault();

          this.path = button.dataset.path;
          this.method = button.dataset.method;
          this.modalAttributes = JSON.parse(button.dataset.modalAttributes);
          this.showModal = true;
        });
      });
    },
    methods: {
      dismiss() {
        this.showModal = false;
      },
    },
    render(h) {
      return h(ConfirmModal, {
        props: {
          path: this.path,
          method: this.method,
          modalAttributes: this.modalAttributes,
          showModal: this.showModal,
        },
        on: { dismiss: this.dismiss },
      });
    },
  }).$mount();
};

export default () => mountConfirmModal();
