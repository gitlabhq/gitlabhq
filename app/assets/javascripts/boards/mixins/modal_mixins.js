import ModalStore from '../stores/modal_store';

export default {
  methods: {
    toggleModal(toggle) {
      ModalStore.store.showAddIssuesModal = toggle;
    },
    changeTab(tab) {
      ModalStore.store.activeTab = tab;
    },
  },
};
