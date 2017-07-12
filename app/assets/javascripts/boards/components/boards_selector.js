import Vue from 'vue';
import './board_new_form';

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
      currentBoard: {
        type: Object,
        required: true,
      },
      milestonePath: {
        type: String,
        required: true,
      },
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
          return 'Edit board name';
        } else if (this.currentPage === 'milestone') {
          return 'Edit board milestone';
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
        this.state.reload = false;
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
          gl.boardService.allBoards()
            .then(res => res.json())
            .then((json) => {
              this.loading = false;
              this.boards = json;
            })
            .catch(() => {
              this.loading = false;
            });
        }
      },
    },
    created() {
      this.state.currentBoard = this.currentBoard;
    },
  });
})();
