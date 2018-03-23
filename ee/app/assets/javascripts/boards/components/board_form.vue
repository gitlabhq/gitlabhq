<script>
/* global ListLabel */
/* global BoardService */

import Flash from '~/flash';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';
import BoardLabelsSelect from '~/vue_shared/components/sidebar/labels_select/base.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import BoardMilestoneSelect from './milestone_select.vue';
import BoardWeightSelect from './weight_select.vue';
import AssigneeSelect from './assignee_select.vue';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

const Store = gl.issueBoards.BoardsStore;
const boardDefaults = {
  id: false,
  name: '',
  labels: [],
  milestone_id: undefined,
  assignee: {},
  assignee_id: undefined,
  weight: null,
};

export default {
  components: {
    AssigneeSelect,
    BoardLabelsSelect,
    BoardMilestoneSelect,
    BoardWeightSelect,
    DeprecatedModal,
  },
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
      type: Number,
      required: false,
      default: 0,
    },
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    weights: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      board: { ...boardDefaults, ...this.currentBoard },
      expanded: false,
      issue: {},
      currentBoard: Store.state.currentBoard,
      currentPage: Store.state.currentPage,
      milestones: [],
      milestoneDropdownOpen: false,
      isLoading: false,
    };
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
    isVisible() {
      return this.currentPage !== '';
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
    },
    submitDisabled() {
      return this.isLoading || this.board.name.length === 0;
    },
  },
  mounted() {
    this.resetFormState();
    if (this.$refs.name) {
      this.$refs.name.focus();
    }
  },
  methods: {
    handleLabelClick(label) {
      if (label.isAny) {
        this.board.labels = [];
      } else if (!this.board.labels.find(l => l.id === label.id)) {
        this.board.labels.push(
          new ListLabel({
            id: label.id,
            title: label.title,
            color: label.color[0],
            textColor: label.text_color,
          }),
        );
      } else {
        let labels = this.board.labels;
        labels = labels.filter(selected => selected.id !== label.id);
        this.board.labels = labels;
      }
    },
    submit() {
      if (this.board.name.length === 0) return;
      this.isLoading = true;
      if (this.isDeleteForm) {
        gl.boardService
          .deleteBoard(this.currentBoard)
          .then(() => {
            visitUrl(Store.rootPath);
          })
          .catch(() => {
            Flash('Failed to delete board. Please try again.');
            this.isLoading = false;
          });
      } else {
        gl.boardService
          .createBoard(this.board)
          .then(resp => resp.data)
          .then(data => {
            visitUrl(data.board_path);
          })
          .catch(() => {
            Flash('Unable to save your changes. Please try again.');
            this.isLoading = false;
          });
      }
    },
    cancel() {
      Store.state.currentPage = '';
    },
    resetFormState() {
      if (this.isNewForm) {
        // Clear the form when we open the "New board" modal
        this.board = { ...boardDefaults };
      } else if (this.currentBoard && Object.keys(this.currentBoard).length) {
        this.board = { ...boardDefaults, ...this.currentBoard };
      }
    },
  },
};
</script>

<template>
  <deprecated-modal
    v-show="isVisible"
    modal-dialog-class="board-config-modal"
    :hide-footer="readonly"
    :title="title"
    :primary-button-label="buttonText"
    :kind="buttonKind"
    :submit-disabled="submitDisabled"
    @cancel="cancel"
    @submit="submit"
  >
    <template slot="body">
      <p v-if="isDeleteForm">
        Are you sure you want to delete this board?
      </p>
      <form
        v-else
        class="js-board-config-modal"
        @submit.prevent
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
            @keyup.enter="submit"
            placeholder="Enter board name"
          />
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
              :can-edit="canAdminBoard"
            />

            <board-labels-select
              ability-name="issue"
              :context="board"
              :labels-path="labelsPath"
              :can-edit="canAdminBoard"
              @onLabelClick="handleLabelClick"
            >
              {{ __('Any Label') }}
            </board-labels-select>

            <assignee-select
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
    </template>
  </deprecated-modal>
</template>
