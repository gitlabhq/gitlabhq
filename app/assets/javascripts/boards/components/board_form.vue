<template>
        <!-- TODO: handle Delete button with btn-danger class and method delete to link_to current_board_path(board) -->
  <popup-dialog
    v-show="currentPage"
    :title="title"
    :primaryButtonLabel="buttonText"
    :kind="buttonKind"
    @toggle="cancel"
    @submit="submit"
  >
    <p v-if="currentPage === 'delete'">
      Are you sure you want to delete this board?
    </p>
    <form
      v-else
      class="js-board-config-modal"
    >
      <div
        v-if="!readonly"
        class="append-bottom-20"
      >
        <label class="form-section-title label-light" for="board-new-name">
          Board name
        </label>
        <input
          ref="name"
          class="form-control"
          type="text"
          id="board-new-name"
          v-model="board.name"
        >
      </div>
      <div v-if="scopedIssueBoardFeatureEnabled">
        <div
          v-if="canAdminBoard"
          class="media append-bottom-10"
        >
          <label class="form-section-title label-light media-body">
            Board scope
          </label>
          <button
            type="button"
            class="btn"
            @click="expanded = !expanded"
            v-if="collapseScope"
          >
            {{ expandButtonText }}
          </button>
        </div>
        <div v-if="!collapseScope || expanded">
          <p class="light append-bottom-10">
            Board scope affects which issues are displayed for anyone who visits this board
          </p>

          <form-block
          >
            <div
              v-if="board.milestone"
              slot="currentValue"
            >
              {{ board.milestone.title }}
            </div>
            <board-milestone-select
              :board="board"
              :milestone-path="milestonePath"
              v-model="board.milestone_id"
              title="Milestone"
              defaultText="Any milestone"
              :canEdit="canAdminBoard"
            />
          </form-block>

          <form-block>
            <board-labels-select
              :board="board"
              title="Labels"
              defaultText="Any label"
              :canEdit="canAdminBoard"
              :labelsPath="labelsPath"
            />
          </form-block>

          <form-block>
            <assignee-select
              :board="board"
              :canEdit="canAdminBoard"
              :project-id="projectId"
              :group-id="groupId"
            />
          </form-block>

          <form-block
            title="Weight"
            defaultText="Any weight"
            :fieldName="'board_filter[weight]'"
            :canEdit="canAdminBoard"
          >
            <board-weight-select
              :board="board"
              v-model="board.weight"
              title="Weight"
              defaultText="Any weight"
              :canEdit="canAdminBoard"
            />
          </form-block>
        </div>
      </div>
    </form>
    <div
      slot="footer"
      v-if="readonly"
    ></div>
  </popup-dialog>
</template>

<script>
/* global BoardService */

import Vue from 'vue';
import PopupDialog from '~/vue_shared/components/popup_dialog.vue';
import FormBlock from './form_block.vue';
import BoardMilestoneSelect from './milestone_select.vue';
import BoardWeightSelect from './weight_select.vue';
import BoardLabelsSelect from './labels_select.vue';
import AssigneeSelect from './assignee_select.vue';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;

export default Vue.extend({
  props: {
    milestonePath: {
      type: String,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    scopedIssueBoardFeatureEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    groupId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      board: Store.boardConfig,
      expanded: false,
      issue: {},
      currentBoard: Store.state.currentBoard,
      currentPage: Store.state.currentPage,
      milestones: [],
      milestoneDropdownOpen: false,
    };
  },
  components: {
    AssigneeSelect,
    BoardLabelsSelect,
    BoardMilestoneSelect,
    BoardWeightSelect,
    FormBlock,
    PopupDialog,
  },
  mounted() {
    if (this.currentBoard && Object.keys(this.currentBoard).length && this.currentPage !== 'new') {
      Store.updateBoardConfig(this.currentBoard);
    } else {
      Store.updateBoardConfig({
        name: '',
        id: false,
        label_ids: [],
      });
    }

    if (!this.board.labels) {
      this.board.labels = [];
    }

    if (this.$refs.name) {
      this.$refs.name.focus();
    }
  },
  computed: {
    buttonText() {
      if (this.currentPage === 'new') {
        return 'Create';
      }

      if (this.currentPage === 'delete') {
        return 'Delete';
      }

      return 'Save';
    },
    buttonKind() {
      if (this.currentPage === 'delete') {
        return 'danger';
      }
      return 'info';
    },
    title() {
      if (this.currentPage === 'new') {
        return 'Create new board';
      }

      if (this.currentPage === 'delete') {
        return 'Delete board';
      }

      if (this.readonly) {
        return 'Board scope';
      }

      return 'Edit board';
    },
    milestoneToggleText() {
      return this.board.milestone ? this.board.milestone.title : 'Milestone';
    },
    submitDisabled() {
      return false;
    },
    expandButtonText() {
      return this.expanded ? 'Collapse' : 'Expand';
    },
    collapseScope() {
      return this.currentPage === 'new';
    },
    readonly() {
      return !this.canAdminBoard;
    },
  },
  methods: {
    refreshPage() {
      location.href = location.pathname;
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
  },
});
</script>
