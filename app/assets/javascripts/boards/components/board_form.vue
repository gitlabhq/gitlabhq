<script>
import { GlModal } from '@gitlab/ui';
import { pick } from 'lodash';
import { __, s__ } from '~/locale';
import { deprecatedCreateFlash as Flash } from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import boardsStore from '~/boards/stores/boards_store';
import { fullBoardId, getBoardsPath } from '../boards_util';

import BoardConfigurationOptions from './board_configuration_options.vue';
import createBoardMutation from '../graphql/board.mutation.graphql';

const boardDefaults = {
  id: false,
  name: '',
  labels: [],
  milestone_id: undefined,
  assignee: {},
  assignee_id: undefined,
  weight: null,
  hide_backlog_list: false,
  hide_closed_list: false,
};

const formType = {
  new: 'new',
  delete: 'delete',
  edit: 'edit',
};

export default {
  i18n: {
    [formType.new]: { title: s__('Board|Create new board'), btnText: s__('Board|Create board') },
    [formType.delete]: { title: s__('Board|Delete board'), btnText: __('Delete') },
    [formType.edit]: { title: s__('Board|Edit board'), btnText: __('Save changes') },
    scopeModalTitle: s__('Board|Board scope'),
    cancelButtonText: __('Cancel'),
    deleteErrorMessage: s__('Board|Failed to delete board. Please try again.'),
    saveErrorMessage: __('Unable to save your changes. Please try again.'),
    deleteConfirmationMessage: s__('Board|Are you sure you want to delete this board?'),
    titleFieldLabel: __('Title'),
    titleFieldPlaceholder: s__('Board|Enter board name'),
  },
  components: {
    BoardScope: () => import('ee_component/boards/components/board_scope.vue'),
    GlModal,
    BoardConfigurationOptions,
  },
  props: {
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    labelsWebUrl: {
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
    currentBoard: {
      type: Object,
      required: true,
    },
  },
  inject: {
    endpoints: {
      default: {},
    },
  },
  data() {
    return {
      board: { ...boardDefaults, ...this.currentBoard },
      currentPage: boardsStore.state.currentPage,
      isLoading: false,
    };
  },
  computed: {
    isNewForm() {
      return this.currentPage === formType.new;
    },
    isDeleteForm() {
      return this.currentPage === formType.delete;
    },
    isEditForm() {
      return this.currentPage === formType.edit;
    },
    buttonText() {
      return this.$options.i18n[this.currentPage].btnText;
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
      if (this.readonly) {
        return this.$options.i18n.scopeModalTitle;
      }

      return this.$options.i18n[this.currentPage].title;
    },
    readonly() {
      return !this.canAdminBoard;
    },
    submitDisabled() {
      return this.isLoading || this.board.name.length === 0;
    },
    primaryProps() {
      return {
        text: this.buttonText,
        attributes: [
          {
            variant: this.buttonKind,
            disabled: this.submitDisabled,
            loading: this.isLoading,
            'data-qa-selector': 'save_changes_button',
          },
        ],
      };
    },
    cancelProps() {
      return {
        text: this.$options.i18n.cancelButtonText,
      };
    },
    boardPayload() {
      const { assignee, milestone, labels } = this.board;
      return {
        ...this.board,
        assignee_id: assignee?.id,
        milestone_id: milestone?.id,
        label_ids: labels.length ? labels.map(b => b.id) : [''],
      };
    },
  },
  mounted() {
    this.resetFormState();
    if (this.$refs.name) {
      this.$refs.name.focus();
    }
  },
  methods: {
    callBoardMutation(id) {
      return this.$apollo.mutate({
        mutation: createBoardMutation,
        variables: {
          ...pick(this.boardPayload, ['hideClosedList', 'hideBacklogList']),
          id,
        },
      });
    },
    async updateBoard() {
      const responses = await Promise.all([
        // Remove unnecessary REST API call when https://gitlab.com/gitlab-org/gitlab/-/issues/282299#note_462996301 is resolved
        getBoardsPath(this.endpoints.boardsEndpoint, this.boardPayload),
        this.callBoardMutation(fullBoardId(this.boardPayload.id)),
      ]);

      return responses[0].data;
    },
    async createBoard() {
      // TODO: change this to use `createBoard` mutation https://gitlab.com/gitlab-org/gitlab/-/issues/292466 is resolved
      const boardData = await getBoardsPath(this.endpoints.boardsEndpoint, this.boardPayload);
      this.callBoardMutation(fullBoardId(boardData.data.id));

      return boardData.data || boardData;
    },
    submit() {
      if (this.board.name.length === 0) return;
      this.isLoading = true;
      if (this.isDeleteForm) {
        boardsStore
          .deleteBoard(this.currentBoard)
          .then(() => {
            this.isLoading = false;
            visitUrl(boardsStore.rootPath);
          })
          .catch(() => {
            Flash(this.$options.i18n.deleteErrorMessage);
            this.isLoading = false;
          });
      } else {
        const boardAction = this.boardPayload.id ? this.updateBoard : this.createBoard;
        boardAction()
          .then(data => {
            visitUrl(data.board_path);
          })
          .catch(() => {
            Flash(this.$options.i18n.saveErrorMessage);
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
  <gl-modal
    modal-id="board-config-modal"
    modal-class="board-config-modal"
    content-class="gl-absolute gl-top-7"
    visible
    :hide-footer="readonly"
    :title="title"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="submit"
    @cancel="cancel"
    @close="cancel"
    @hide.prevent
  >
    <p v-if="isDeleteForm" data-testid="delete-confirmation-message">
      {{ $options.i18n.deleteConfirmationMessage }}
    </p>
    <form v-else class="js-board-config-modal" data-testid="board-form-wrapper" @submit.prevent>
      <div v-if="!readonly" class="gl-mb-5" data-testid="board-form">
        <label class="gl-font-weight-bold gl-font-lg" for="board-new-name">
          {{ $options.i18n.titleFieldLabel }}
        </label>
        <input
          id="board-new-name"
          ref="name"
          v-model="board.name"
          class="form-control"
          data-qa-selector="board_name_field"
          type="text"
          :placeholder="$options.i18n.titleFieldPlaceholder"
          @keyup.enter="submit"
        />
      </div>

      <board-configuration-options
        :is-new-form="isNewForm"
        :board="board"
        :current-board="currentBoard"
      />

      <board-scope
        v-if="scopedIssueBoardFeatureEnabled"
        :collapse-scope="isNewForm"
        :board="board"
        :can-admin-board="canAdminBoard"
        :labels-path="labelsPath"
        :labels-web-url="labelsWebUrl"
        :enable-scoped-labels="enableScopedLabels"
        :project-id="projectId"
        :group-id="groupId"
        :weights="weights"
      />
    </form>
  </gl-modal>
</template>
