<template>
  <popup-dialog :title="title" >
    <p v-if="currentPage === 'delete'">
      Are you sure you want to delete this board?
    </p>
    <form
      v-else
      @submit="submit"
    >
      <div>
        <label class="label-light" for="board-new-name">
          Board name
        </label>
        <input
          class="form-control"
          type="text"
          id="board-new-name"
          v-model="board.name"
        >
      </div>
      <div>
        <button
          type="button"
          class="btn pull-right"
          @click="expand = !expand">
          Expand
        </button>
        <h3>
          Board scope
        </h3>
      </div>
      <transition name="fade">
        <div v-show="expand">
          <p>
            Board scope affects which issues are displayed for anyone who visits this board
          </p>

          <!-- TODO: if current_board_parent.issue_board_milestone_available?(current_user) -->
            <input
              type="hidden"
              id="board-milestone"
              v-model.number="board.milestone_id">
            <board-milestone-select
              :board="board"
              :milestone-path="milestonePath"
              :select-milestone="selectMilestone">
            </board-milestone-select>
        </div>
      </transition>
    </form>
    <template slot="footer">
      <!-- TODO: handle Delete button with btn-danger class and method delete to link_to current_board_path(board) -->
      <button
        class="btn btn-primary pull-left"
        @click="submit"
        type="button"
      >
        {{ buttonText }}
      </button>
      <button
        class="btn btn-default pull-right"
        type="button"
      >
        Cancel
      </button>
    </template>
  </popup-dialog>
</template>

<script>
/* global BoardService */

import Vue from 'vue';
import PopupDialog from '~/vue_shared/components/popup_dialog.vue';
import boardMilestoneSelect from './milestone_select';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;

export default Vue.extend({
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
      },
      expand: false,
      issue: {},
      currentBoard: Store.state.currentBoard,
      currentPage: Store.state.currentPage,
      milestones: [],
      milestoneDropdownOpen: false,
    };
  },
  components: {
    boardMilestoneSelect,
    PopupDialog,
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
    title() {
      if (this.currentPage === 'new') {
        return 'Create new board';
      }

      // TODO check for readonly
      return 'Edit board';
    },
    milestoneToggleText() {
      return this.board.milestone ? this.board.milestone.title : 'Milestone';
    },
    submitDisabled() {
      return false;
    },
  },
  methods: {
    refreshPage() {
      location.href = location.pathname;
    },
    loadMilestones(e) {
      this.milestoneDropdownOpen = !this.milestoneDropdownOpen;
      BoardService.loadMilestones.call(this);

      if (this.milestoneDropdownOpen) {
        this.$nextTick(() => {
          const milestoneDropdown = this.$refs.milestoneDropdown;
          const rect = e.target.getBoundingClientRect();

          milestoneDropdown.style.width = `${rect.width}px`;
        });
      }
    },
    submit() {
      gl.boardService.createBoard(this.board)
        .then(resp => resp.json())
        .then((data) => {
          if (this.currentBoard && this.currentPage !== 'new') {
            this.currentBoard.name = this.board.name;

            // We reload the page to make sure the store & state of the app are correct
            this.refreshPage();

            // Enable the button thanks to our jQuery disabling it
            $(this.$refs.submitBtn).enable();

            // Reset the selectors current page
            Store.state.currentPage = '';
            Store.state.reload = true;
          } else if (this.currentPage === 'new') {
            gl.utils.visitUrl(`${Store.rootPath}/${data.id}`);
          }
        })
        .catch(() => {
          // https://gitlab.com/gitlab-org/gitlab-ce/issues/30821
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
</script>
