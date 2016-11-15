//= require ./board_new_form

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  const Store = gl.issueBoards.BoardsStore;

  Store.createNewListDropdownData();

  gl.issueBoards.BoardsSelector = Vue.extend({
    components: {
      'board-selector-form': gl.issueBoards.BoardSelectorForm,
    },
    props: {
      currentBoard: Object,
      endpoint: String,
    },
    data() {
      return {
        open: false,
        loading: true,
        boards: [],
        state: Store.state,
      };
    },
    watch: {
      reload() {
        if (this.reload) {
          this.boards = [];
          this.loading = true;
          this.reload = false;

          this.loadBoards(false);
        }
      },
    },
    computed: {
      currentPage() {
        return this.state.currentPage;
      },
      reload() {
        return this.state.reload;
      },
      board() {
        return this.state.currentBoard;
      },
      showDelete() {
        return this.boards.length > 1;
      },
      title() {
        if (this.currentPage === 'edit') {
          return 'Edit board';
        } else if (this.currentPage === 'new') {
          return 'Create new board';
        } else if (this.currentPage === 'delete') {
          return 'Delete board';
        }

        return 'Go to a board';
      },
    },
    methods: {
      showPage(page) {
        this.state.currentPage = page;
      },
      toggleDropdown() {
        this.open = !this.open;
      },
      loadBoards(toggleDropdown = true) {
        if (toggleDropdown) {
          this.toggleDropdown();
        }

        if (this.open && !this.boards.length) {
          gl.boardService.allBoards().then((resp) => {
            this.loading = false;
            this.boards = resp.json();
          });
        }
      },
    },
    created() {
      this.state.currentBoard = this.currentBoard;
    },
  });
})();
