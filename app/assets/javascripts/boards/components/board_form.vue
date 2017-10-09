<script>
/* global BoardService */

import Vue from 'vue';
import PopupDialog from '~/vue_shared/components/popup_dialog.vue';
import BoardMilestoneSelect from './milestone_select.vue';
import BoardWeightSelect from './weight_select.vue';
import BoardLabelsSelect from './labels_select.vue';
import UserSelect from './user_select.vue';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;

export default {
  props: {
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
    PopupDialog,
    UserSelect,
  },
  computed: {
    isNewForm() {
      return this.currentPage === 'new';
    },
    isDeleteForm() {
      return this.currentPage === 'delete';
    },
    isEditForm() {
      return this.currentPage === 'edit';
    },
    buttonText() {
      if (this.isNewForm) {
        return 'Create board';
      }
      if (this.isDeleteForm) {
        return 'Delete';
      }
      return 'Save changes';
    },
    buttonKind() {
      if (this.isNewForm) {
        return 'success';
      }
      if (this.isDeleteForm) {
        return 'danger';
      }
      return 'info';
    },
    title() {
      if (this.isNewForm) {
        return 'Create new board';
      }
      if (this.isDeleteForm) {
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
      return this.isNewForm;
    },
    readonly() {
      return !this.canAdminBoard;
    },
    weightsArray() {
      return JSON.parse(this.weights);
    }
  },
  methods: {
    submit() {
      if (this.isDeleteForm) {
        this.submitDisabled = true;
        gl.boardService.deleteBoard(this.currentBoard)
          .then(() => {
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
            gl.utils.visitUrl(`${Store.rootPath}/${data.id}`);
          })
          .catch(() => {
            Flash('Unable to save your changes. Please try again.')
          });
      }
    },
    cancel() {
      Store.state.currentPage = '';
    },
    resetFormState() {
      if (this.isNewForm) {
        // Clear the form when we open the "New board" modal
        Store.updateBoardConfig();
      } else if (this.currentBoard && Object.keys(this.currentBoard).length) {
        Store.updateBoardConfig(this.currentBoard);
      }
    },
  },
  mounted() {
    this.resetFormState();

    if (this.$refs.name) {
      this.$refs.name.focus();
    }
  },
};
</script>

<template>
  <popup-dialog
    v-show="currentPage"
    :title="title"
    :primary-button-label="buttonText"
    :kind="buttonKind"
    :submit-disabled="submitDisabled"
    @toggle="cancel"
    @submit="submit"
  >
    <p v-if="isDeleteForm">
      Are you sure you want to delete this board?
    </p>
    <form
      v-else
      class="js-board-config-modal board-config-modal"
    >
      <div
        v-if="!readonly"
        class="append-bottom-20"
      >
        <label
          class="form-section-title label-light"
          for="board-new-name"
        >
          Board name
        </label>
        <input
          ref="name"
          class="form-control"
          type="text"
          id="board-new-name"
          v-model="board.name"
          placeholder="Enter board name"
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
        <p class="text-secondary append-bottom-10">
          Board scope affects which issues are displayed for anyone who visits this board
        </p>
        <div v-if="!collapseScope || expanded">
          <board-milestone-select
            :board="board"
            :milestone-path="milestonePath"
            title="Milestone"
            :can-edit="canAdminBoard"
          />

          <board-labels-select
            :board="board"
            :selected="board.labels"
            title="Labels"
            :can-edit="canAdminBoard"
            :labels-path="labelsPath"
          />

          <user-select
            any-user-text="Any assignee"
            :board="board"
            field-name="assignee_id"
            label="Assignee"
            :selected="board.assignee"
            :can-edit="canAdminBoard"
            placeholder-text="Select assignee"
            :project-id="projectId"
            :group-id="groupId"
            wrapper-class="assignee"
          />

          <board-weight-select
            :board="board"
            :weights="weightsArray"
            v-model="board.weight"
            :can-edit="canAdminBoard"
          />
        </div>
      </div>
    </form>
    <div
      slot="footer"
      v-if="readonly"
    ></div>
  </popup-dialog>
</template>
