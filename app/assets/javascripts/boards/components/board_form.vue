<template>
        <!-- TODO: handle Delete button with btn-danger class and method delete to link_to current_board_path(board) -->
  <popup-dialog
    v-show="currentPage"
    :title="title"
    :primary-button-label="buttonText"
    :kind="buttonKind"
    :submit-disabled="submitDisabled"
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
              :can-edit="canAdminBoard"
            />
          </form-block>

          <form-block>
            <board-labels-select
              :board="board"
              :selected="board.labels"
              title="Labels"
              default-text="Any label"
              :can-edit="canAdminBoard"
              :labels-path="labelsPath"
            />
          </form-block>

          <form-block>
            <user-select
              any-user-text="Any assignee"
              :board="board"
              field-name="assignee_id"
              label="Assignee"
              v-model="board.assignee_id"
              :selected="board.assignee"
              :can-edit="canAdminBoard"
              placeholder-text="Select assignee"
              :project-id="projectId"
              :group-id="groupId"
              wrapper-class="assignee"
            />
          </form-block>

          <form-block
            title="Weight"
            defaultText="Any weight"
            field-name="'board_filter[weight]'"
            :can-edit="canAdminBoard"
          >
            <board-weight-select
              :board="board"
              :weights="weightsArray"
              v-model="board.weight"
              title="Weight"
              defaultText="Any weight"
              :can-edit="canAdminBoard"
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
import UserSelect from './user_select.vue';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;

export default Vue.extend({
  props: {
    boardPath: {
      type: String,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    labelsPath: {
      type: String,
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
    weights: {
      type: String,
      required: false,
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
      submitDisabled: false,
    };
  },
  components: {
    BoardLabelsSelect,
    BoardMilestoneSelect,
    BoardWeightSelect,
    FormBlock,
    PopupDialog,
    UserSelect,
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
    expandButtonText() {
      return this.expanded ? 'Collapse' : 'Expand';
    },
    collapseScope() {
      return this.currentPage === 'new';
    },
    readonly() {
      return !this.canAdminBoard;
    },
    weightsArray() {
      return JSON.parse(this.weights);
    }
  },
  methods: {
    refreshPage() {
      location.href = location.pathname;
    },
    submit() {
      if (this.currentPage === 'delete') {
        this.submitDisabled = true;
        this.$http.delete(this.boardPath)
          .then(({redirect_to}) => {
            gl.utils.visitUrl(Store.rootPath);
          })
          .catch(() => {
            Flash('Failed to delete board. Please try again.')
            this.submitDisabled = false;
          });
      } else {
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
            Flash('Unable to save your changes. Please try again.')
          });
      }
    },
    cancel() {
      Store.state.currentPage = '';
    },
  },
  mounted() {
    if (this.currentBoard && Object.keys(this.currentBoard).length && this.currentPage !== 'new') {
      Store.updateBoardConfig(this.currentBoard);
    } else {
      Store.updateBoardConfig({
        name: '',
        id: false,
        label_ids: [],
        assignee: {},
      });
    }

    if (!this.board.labels) {
      this.board.labels = [];
    }

    if (this.$refs.name) {
      this.$refs.name.focus();
    }
  },
});
</script>
