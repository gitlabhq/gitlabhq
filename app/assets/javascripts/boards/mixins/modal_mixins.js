const { ModalStore } = gl.issueBoards;

gl.issueBoards.ModalMixins = {
  methods: {
    toggleModal(toggle) {
      ModalStore.store.showAddIssuesModal = toggle;
    },
    changeTab(tab) {
      ModalStore.store.activeTab = tab;
    },
  },
};
