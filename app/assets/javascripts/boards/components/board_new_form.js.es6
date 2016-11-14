(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  const Store = gl.issueBoards.BoardsStore;

  gl.issueBoards.BoardSelectorForm = Vue.extend({
    data() {
      return {
        board: {
          id: false,
          name: '',
        },
        currentBoard: Store.state.currentBoard,
        currentPage: Store.state.currentPage,
      };
    },
    mounted() {
      if (this.currentBoard && Object.keys(this.currentBoard).length && this.currentPage === 'edit') {
        this.board = Vue.util.extend({}, this.currentBoard);
      }
    },
    computed: {
      buttonText() {
        if (this.currentPage === 'new') {
          return 'Create';
        }

        return 'Save';
      },
    },
    methods: {
      submit() {
        gl.boardService.createBoard(this.board)
          .then(() => {
            if (this.currentBoard && this.currentPage === 'edit') {
              this.currentBoard.name = this.board.name;
            }

            // Enable the button thanks to our jQuery disabling it
            $(this.$refs.submitBtn).enable();

            // Reset the selectors current page
            Store.state.currentPage = '';
            Store.state.reload = true;
          });
      },
    },
  });
})();
