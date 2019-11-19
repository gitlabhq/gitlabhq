<script>
import { __ } from '~/locale';
import Flash from '~/flash';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import boardsStore from '~/boards/stores/boards_store';

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
    BoardScope: () => import('ee_component/boards/components/board_scope.vue'),
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
      type: Array,
      required: false,
      default: () => [],
    },
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    scopedLabelsDocumentationLink: {
      type: String,
      required: false,
      default: '#',
    },
  },
  data() {
    return {
      board: { ...boardDefaults, ...this.currentBoard },
      currentBoard: boardsStore.state.currentBoard,
      currentPage: boardsStore.state.currentPage,
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
        return __('Create board');
      }
      if (this.isDeleteForm) {
        return __('Delete');
      }
      return __('Save changes');
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
        return __('Create new board');
      }
      if (this.isDeleteForm) {
        return __('Delete board');
      }
      if (this.readonly) {
        return __('Board scope');
      }
      return __('Edit board');
    },
    readonly() {
      return !this.canAdminBoard;
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
    submit() {
      if (this.board.name.length === 0) return;
      this.isLoading = true;
      if (this.isDeleteForm) {
        boardsStore
          .deleteBoard(this.currentBoard)
          .then(() => {
            visitUrl(boardsStore.rootPath);
          })
          .catch(() => {
            Flash(__('Failed to delete board. Please try again.'));
            this.isLoading = false;
          });
      } else {
        boardsStore
          .createBoard(this.board)
          .then(resp => resp.data)
          .then(data => {
            visitUrl(data.board_path);
          })
          .catch(() => {
            Flash(__('Unable to save your changes. Please try again.'));
            this.isLoading = false;
          });
      }
    },
    cancel() {
      boardsStore.showPage('');
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
    :hide-footer="readonly"
    :title="title"
    :primary-button-label="buttonText"
    :kind="buttonKind"
    :submit-disabled="submitDisabled"
    modal-dialog-class="board-config-modal"
    @cancel="cancel"
    @submit="submit"
  >
    <template slot="body">
      <p v-if="isDeleteForm">{{ __('Are you sure you want to delete this board?') }}</p>
      <form v-else class="js-board-config-modal" @submit.prevent>
        <div v-if="!readonly" class="append-bottom-20">
          <label class="form-section-title label-bold" for="board-new-name">{{
            __('Board name')
          }}</label>
          <input
            id="board-new-name"
            ref="name"
            v-model="board.name"
            class="form-control"
            data-qa-selector="board_name_field"
            type="text"
            :placeholder="__('Enter board name')"
            @keyup.enter="submit"
          />
        </div>

        <board-scope
          v-if="scopedIssueBoardFeatureEnabled"
          :collapse-scope="isNewForm"
          :board="board"
          :can-admin-board="canAdminBoard"
          :milestone-path="milestonePath"
          :labels-path="labelsPath"
          :scoped-labels-documentation-link="scopedLabelsDocumentationLink"
          :enable-scoped-labels="enableScopedLabels"
          :project-id="projectId"
          :group-id="groupId"
          :weights="weights"
        />
      </form>
    </template>
  </deprecated-modal>
</template>
