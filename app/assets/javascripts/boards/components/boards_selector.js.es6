//= require ./board_new_form

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardsSelector = Vue.extend({
    components: {
      'board-selector-form': gl.issueBoards.BoardSelectorForm
    },
    props: {
      currentBoard: Object,
      endpoint: String
    },
    data () {
      return {
        open: false,
        loading: true,
        boards: [],
        currentPage: '',
        reload: false
      };
    },
    watch: {
      reload () {
        if (this.reload) {
          this.boards = [];
          this.loading = true;
          this.reload = false;

          this.loadBoards(false);
        }
      }
    },
    computed: {
      showDelete () {
        return this.boards.length > 1;
      },
      title () {
        if (this.currentPage === 'edit') {
          return 'Edit board';
        } else if (this.currentPage === 'new') {
          return 'Create new board';
        } else if (this.currentPage === 'delete') {
          return 'Delete board';
        } else {
          return 'Go to a board';
        }
      }
    },
    methods: {
      showPage (page) {
        this.currentPage = page;
      },
      toggleDropdown () {
        this.open = !this.open;
      },
      loadBoards (toggleDropdown = true) {
        if (toggleDropdown) {
          this.toggleDropdown();
        }

        if (this.open && !this.boards.length) {
          this.$http.get(this.endpoint).then((resp) => {
            this.loading = false;
            this.boards = resp.json();
          });
        }
      }
    }
  });
})();
