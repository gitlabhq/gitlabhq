/* global Vue */
/* eslint-disable */
const boardMilestoneSelect = require('./milestone_select');
(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  const Store = gl.issueBoards.BoardsStore;

  gl.issueBoards.BoardSelectorForm = Vue.extend({
    props: {
      milestonePath: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        board: {
          id: false,
          name: '',
          milestone: {},
          milestone_id: '',
        },
        currentBoard: Store.state.currentBoard,
        currentPage: Store.state.currentPage,
        milestones: [],
        milestoneDropdownOpen: false,
      };
    },
    components: {
      boardMilestoneSelect,
    },
    mounted() {
      if (this.currentBoard && Object.keys(this.currentBoard).length && this.currentPage !== 'new') {
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
      milestoneToggleText() {
        return this.board.milestone.title || 'Milestone';
      },
      submitDisabled() {
        if (this.currentPage !== 'milestone') {
          return this.board.name === '';
        }

        return false;
      },
    },
    methods: {
      loadMilestones() {
        this.milestoneDropdownOpen = !this.milestoneDropdownOpen;

        if (!this.milestones.length) {
          this.$http.get(this.milestonePath)
            .then((res) => {
              this.milestones = res.json();
            });
        }
      },
      submit() {
        gl.boardService.createBoard(this.board)
          .then(() => {
            if (this.currentBoard && this.currentPage !== 'new') {
              this.currentBoard.name = this.board.name;

              if (this.board.milestone) {
                this.currentBoard.milestone_id = this.board.milestone_id;
                this.currentBoard.milestone = this.board.milestone;

                Store.state.filters.milestone_title = this.currentBoard.milestone_id ? this.currentBoard.milestone.title : null;
              }
            }

            // Enable the button thanks to our jQuery disabling it
            $(this.$refs.submitBtn).enable();

            // Reset the selectors current page
            Store.state.currentPage = '';
            Store.state.reload = true;
          });
      },
      cancel() {
        Store.state.currentPage = '';
      },
      selectMilestone(milestone) {
        this.milestoneDropdownOpen = false;
        this.board.milestone_id = milestone.id;
        this.board.milestone = {
          title: milestone.title,
        };
      },
    },
  });
})();
