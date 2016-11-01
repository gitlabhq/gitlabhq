(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardSelectorForm = Vue.extend({
    props: {
      type: String,
      currentBoard: Object,
      currentPage: String,
      reload: Boolean,
    },
    data() {
      return {
        board: {
          id: false,
          name: '',
        },
      };
    },
    ready() {
      if (this.currentBoard && Object.keys(this.currentBoard).length) {
        this.board = Vue.util.extend({}, this.currentBoard);
      }
    },
    computed: {
      buttonText() {
        if (this.type === 'new') {
          return 'Create';
        }

        return 'Save';
      },
    },
    methods: {
      submit() {
        gl.boardService.createBoard(this.board)
          .then(() => {
            if (this.currentBoard) {
              this.currentBoard.name = this.board.name;
            }

            // Enable the button thanks to our jQuery disabling it
            $(this.$els.submitBtn).enable();

            // Reset the selectors current page
            this.currentPage = '';
            this.reload = true;
          });
      },
    },
  });
})();
