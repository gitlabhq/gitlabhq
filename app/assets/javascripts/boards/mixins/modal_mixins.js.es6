/* global Cookies */
(() => {
  const Store = gl.issueBoards.BoardsStore;
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalMixins = {
    methods: {
      toggleModal(toggleModal, setCookie = true) {
        if (setCookie) {
          Cookies.set('boards_backlog_help_hidden', true);
          Store.state.helpHidden = true;
        }

        ModalStore.store.showAddIssuesModal = toggleModal;
      },
      changeTab(tab) {
        ModalStore.store.activeTab = tab;
      },
    },
  };
})();
