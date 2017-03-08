/* global Vue */

require('./board_new_form');

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
      board: {
        handler() {
          this.updateMilestoneFilterDropdown();
        },
        deep: true,
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
          gl.boardService.allBoards().then((resp) => {
            this.loading = false;
            this.boards = resp.json();
          });
        }
      },
      updateMilestoneFilterDropdown() {
        const $milestoneDropdownToggle = $('.js-milestone-select');
        const glDropdown = $milestoneDropdownToggle.data('glDropdown');
        const $milestoneDropdown = $('.dropdown-menu-milestone');
        const hideElements = this.board.milestone === undefined || this.board.milestone_id === null;

        $('#milestone_title').val(this.board.milestone ? this.board.milestone.title : '');

        if (glDropdown.fullData) {
          glDropdown.parseData(glDropdown.fullData);
        }

        $milestoneDropdown.find('.dropdown-input, .dropdown-footer-list')
          .toggle(hideElements);
        $milestoneDropdown.find('.js-milestone-footer-content').toggle(!hideElements);
        $milestoneDropdown.find('.dropdown-content li').show()
          .filter((i, el) => $(el).find('.is-active').length === 0)
          .toggle(hideElements);

        $('.js-milestone-select .dropdown-toggle-text')
          .text(hideElements ? 'Milestone' : this.board.milestone.title)
          .toggleClass('is-default', hideElements);
      },
    },
    created() {
      this.state.currentBoard = this.currentBoard;
      this.updateMilestoneFilterDropdown();
    },
  });
})();
