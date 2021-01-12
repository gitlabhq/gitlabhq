<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { deprecatedCreateFlash as Flash } from '~/flash';
import { visitUrl, stripFinalUrlSegment } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import boardsStore from '~/boards/stores/boards_store';
import { fullLabelId, fullBoardId } from '../boards_util';

import BoardConfigurationOptions from './board_configuration_options.vue';
import updateBoardMutation from '../graphql/board_update.mutation.graphql';
import createBoardMutation from '../graphql/board_create.mutation.graphql';
import destroyBoardMutation from '../graphql/board_destroy.mutation.graphql';

const boardDefaults = {
  id: false,
  name: '',
  labels: [],
  milestone_id: undefined,
  iteration_id: undefined,
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
  inject: {
    fullPath: {
      default: '',
    },
    rootPath: {
      default: '',
    },
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
    currentMutation() {
      return this.board.id ? updateBoardMutation : createBoardMutation;
    },
    mutationVariables() {
      const { board } = this;
      /* eslint-disable @gitlab/require-i18n-strings */
      let baseMutationVariables = {
        name: board.name,
        hideBacklogList: board.hide_backlog_list,
        hideClosedList: board.hide_closed_list,
      };

      if (this.scopedIssueBoardFeatureEnabled) {
        baseMutationVariables = {
          ...baseMutationVariables,
          weight: board.weight,
          assigneeId: board.assignee?.id ? convertToGraphQLId('User', board.assignee.id) : null,
          milestoneId:
            board.milestone?.id || board.milestone?.id === 0
              ? convertToGraphQLId('Milestone', board.milestone.id)
              : null,
          labelIds: board.labels.map(fullLabelId),
          iterationId: board.iteration_id
            ? convertToGraphQLId('Iteration', board.iteration_id)
            : null,
        };
      }
      /* eslint-enable @gitlab/require-i18n-strings */
      return board.id
        ? {
            ...baseMutationVariables,
            id: fullBoardId(board.id),
          }
        : {
            ...baseMutationVariables,
            projectPath: this.projectId ? this.fullPath : null,
            groupPath: this.groupId ? this.fullPath : null,
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
    setIteration(iterationId) {
      this.board.iteration_id = iterationId;
    },
    async createOrUpdateBoard() {
      const response = await this.$apollo.mutate({
        mutation: this.currentMutation,
        variables: { input: this.mutationVariables },
      });

      return this.board.id
        ? getIdFromGraphQLId(response.data.updateBoard.board.id)
        : getIdFromGraphQLId(response.data.createBoard.board.id);
    },
    async submit() {
      if (this.board.name.length === 0) return;
      this.isLoading = true;
      if (this.isDeleteForm) {
        try {
          await this.$apollo.mutate({
            mutation: destroyBoardMutation,
            variables: {
              id: fullBoardId(this.board.id),
            },
          });
          visitUrl(this.rootPath);
        } catch {
          Flash(this.$options.i18n.deleteErrorMessage);
        } finally {
          this.isLoading = false;
        }
      } else {
        try {
          const path = await this.createOrUpdateBoard();
          const strippedUrl = stripFinalUrlSegment(window.location.href);
          const url = strippedUrl.includes('boards') ? `${path}` : `boards/${path}`;
          visitUrl(url);
        } catch {
          Flash(this.$options.i18n.saveErrorMessage);
        } finally {
          this.isLoading = false;
        }
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
        :hide-backlog-list.sync="board.hide_backlog_list"
        :hide-closed-list.sync="board.hide_closed_list"
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
        @set-iteration="setIteration"
      />
    </form>
  </gl-modal>
</template>
