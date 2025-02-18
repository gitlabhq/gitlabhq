<script>
import { GlForm, GlModal, GlAlert, GlButton } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { formType } from '../constants';

import { setError } from '../graphql/cache_updates';
import errorQuery from '../graphql/client/error.query.graphql';
import createBoardMutation from '../graphql/board_create.mutation.graphql';
import destroyBoardMutation from '../graphql/board_destroy.mutation.graphql';
import updateBoardMutation from '../graphql/board_update.mutation.graphql';
import BoardConfigurationOptions from './board_configuration_options.vue';

const boardDefaults = {
  id: false,
  name: '',
  labels: [],
  milestone: {},
  iterationCadence: {},
  iterationCadenceId: null,
  iteration: {},
  assignee: {},
  weight: null,
  hideBacklogList: false,
  hideClosedList: false,
};

export default {
  i18n: {
    [formType.new]: { title: s__('Boards|Create new board'), btnText: s__('Boards|Create board') },
    [formType.delete]: { title: s__('Boards|Delete board'), btnText: __('Delete') },
    [formType.edit]: { title: s__('Boards|Configure board'), btnText: __('Save changes') },
    scopeModalTitle: s__('Boards|Board configuration'),
    cancelButtonText: __('Cancel'),
    deleteButtonText: s__('Boards|Delete board'),
    deleteErrorMessage: s__('Boards|Failed to delete board. Please try again.'),
    saveErrorMessage: __('Unable to save your changes. Please try again.'),
    deleteConfirmationMessage: s__('Boards|Are you sure you want to delete this board?'),
    lastBoardDefaultMessage: s__(
      'Boards|Because this is the only board here, when this board is deleted, a new default Development board will be created.',
    ),
    lastBoardGroupMessage: s__(
      'Boards|Because this is the only board in this group, when this board is deleted, a new default Development board will be created.',
    ),
    lastBoardProjectMessage: s__(
      'Boards|Because this is the only board in this project, when this board is deleted, a new default Development board will be created.',
    ),
    titleFieldLabel: __('Title'),
    titleFieldPlaceholder: s__('Boards|Enter board name'),
  },
  components: {
    BoardScope: () => import('ee_component/boards/components/board_scope.vue'),
    GlModal,
    GlButton,
    BoardConfigurationOptions,
    GlAlert,
    GlForm,
  },
  inject: {
    fullPath: {
      default: '',
    },
    boardBaseUrl: {
      default: '',
    },
    isGroupBoard: {
      default: false,
    },
    isProjectBoard: {
      default: false,
    },
  },
  props: {
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    scopedIssueBoardFeatureEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    weights: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentBoard: {
      type: Object,
      required: true,
    },
    currentPage: {
      type: String,
      required: true,
    },
    isLastBoard: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentType: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      board: { ...boardDefaults, ...this.currentBoard },
      isLoading: false,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    error: {
      query: errorQuery,
      update: (data) => data.boardsAppError,
    },
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
      if (this.isDeleteForm) {
        return 'danger';
      }
      return 'confirm';
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
        attributes: {
          variant: this.buttonKind,
          disabled: this.submitDisabled,
          loading: this.isLoading,
          'data-testid': 'save-changes-button',
        },
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
    deleteMutation() {
      return destroyBoardMutation;
    },
    baseMutationVariables() {
      const {
        board: { name, hideBacklogList, hideClosedList, id },
      } = this;

      const variables = { name, hideBacklogList, hideClosedList };

      return id
        ? {
            ...variables,
            id,
          }
        : {
            ...variables,
            projectPath: this.isProjectBoard ? this.fullPath : undefined,
            groupPath: this.isGroupBoard ? this.fullPath : undefined,
          };
    },
    mutationVariables() {
      return this.baseMutationVariables;
    },
    canDelete() {
      return this.canAdminBoard && this.isEditForm;
    },
    lastBoardMessage() {
      if (this.parentType === 'group') {
        return this.$options.i18n.lastBoardGroupMessage;
      }
      if (this.parentType === 'project') {
        return this.$options.i18n.lastBoardProjectMessage;
      }
      return this.$options.i18n.lastBoardDefaultMessage;
    },
  },
  mounted() {
    this.resetFormState();
    if (this.$refs.name) {
      this.$refs.name.focus();
    }
    this.$emit('shown');
  },
  methods: {
    setError,
    isFocusMode() {
      return Boolean(document.querySelector('.content-wrapper > .js-focus-mode-board.is-focused'));
    },
    cancel() {
      this.$emit('cancel');
    },
    close() {
      // This calls cancel after the modal has been hidden
      this.$refs.modal.hide();
    },
    async createOrUpdateBoard() {
      const response = await this.$apollo.mutate({
        mutation: this.currentMutation,
        variables: { input: this.mutationVariables },
      });

      if (!this.board.id) {
        return response.data.createBoard.board;
      }

      return response.data.updateBoard.board;
    },
    openDeleteModal() {
      this.$emit('showBoardModal', this.$options.formType.delete);
    },
    async deleteBoard() {
      await this.$apollo.mutate({
        mutation: this.deleteMutation,
        variables: {
          id: this.board.id,
        },
      });
    },
    async submit() {
      if (this.board.name.length === 0) return;
      this.isLoading = true;
      if (this.isDeleteForm) {
        try {
          await this.deleteBoard();
          visitUrl(this.boardBaseUrl);
          this.close();
        } catch (error) {
          setError({ error, message: this.$options.i18n.deleteErrorMessage });
        } finally {
          this.isLoading = false;
        }
      } else {
        try {
          const board = await this.createOrUpdateBoard();
          if (this.board.id) {
            this.$emit('updateBoard', board);
          } else {
            this.$emit('addBoard', board);
          }
          this.close();
        } catch (error) {
          setError({ error, message: this.$options.i18n.saveErrorMessage });
        } finally {
          this.isLoading = false;
        }
      }
    },
    resetFormState() {
      if (this.isNewForm) {
        // Clear the form when we open the "New board" modal
        this.board = { ...boardDefaults };
      } else if (this.currentBoard && Object.keys(this.currentBoard).length) {
        this.board = { ...boardDefaults, ...this.currentBoard };
      }
    },
    setIteration(iteration) {
      this.board.iterationCadenceId = iteration.iterationCadenceId;

      this.board = {
        ...this.board,
        iteration: {
          id: iteration.id,
        },
      };
    },
    setBoardLabels(labels) {
      this.board.labels = labels;
    },
    setAssignee(assigneeId) {
      this.board = {
        ...this.board,
        assignee: {
          id: assigneeId,
        },
      };
    },
    setMilestone(milestoneId) {
      this.board = {
        ...this.board,
        milestone: {
          id: milestoneId,
        },
      };
    },
    setWeight(weight) {
      this.board = {
        ...this.board,
        weight,
      };
    },
  },
  formType,
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="board-config-modal"
    modal-class="board-config-modal"
    content-class="gl-absolute gl-top-7"
    visible
    :static="isFocusMode()"
    :hide-footer="readonly"
    :title="title"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    :no-close-on-backdrop="true"
    @primary.prevent="submit"
    @hidden="cancel"
  >
    <gl-alert
      v-if="error"
      class="gl-mb-3"
      variant="danger"
      :dismissible="true"
      @dismiss="() => setError({ message: null, captureError: false })"
    >
      {{ error }}
    </gl-alert>
    <div v-if="isDeleteForm">
      <p data-testid="delete-confirmation-message">
        {{ $options.i18n.deleteConfirmationMessage }}
      </p>
      <p v-if="isLastBoard" data-testid="delete-last-board-message">
        {{ lastBoardMessage }}
      </p>
    </div>
    <gl-form v-else data-testid="board-form-wrapper" @submit.prevent="submit">
      <div v-if="!readonly" class="gl-mb-5" data-testid="board-form">
        <label class="gl-text-lg gl-font-bold" for="board-new-name">
          {{ $options.i18n.titleFieldLabel }}
        </label>
        <input
          id="board-new-name"
          ref="name"
          v-model="board.name"
          class="form-control"
          data-testid="board-name-field"
          type="text"
          :placeholder="$options.i18n.titleFieldPlaceholder"
        />
      </div>

      <board-configuration-options
        :hide-backlog-list.sync="board.hideBacklogList"
        :hide-closed-list.sync="board.hideClosedList"
        :readonly="readonly"
      />

      <board-scope
        v-if="scopedIssueBoardFeatureEnabled"
        :collapse-scope="isNewForm"
        :board="board"
        :can-admin-board="canAdminBoard"
        :weights="weights"
        @set-iteration="setIteration"
        @set-board-labels="setBoardLabels"
        @set-assignee="setAssignee"
        @set-milestone="setMilestone"
        @set-weight="setWeight"
      />
    </gl-form>
    <template v-if="canDelete" #modal-footer>
      <div class="gl-m-0 gl-flex gl-w-full gl-justify-between">
        <gl-button
          category="secondary"
          variant="danger"
          data-testid="delete-board-button"
          @click="openDeleteModal"
        >
          {{ $options.i18n.deleteButtonText }}</gl-button
        >
        <div class="gl-flex gl-gap-3">
          <gl-button class="!gl-m-0" @click="close">{{ cancelProps.text }}</gl-button
          ><gl-button v-bind="primaryProps.attributes" class="!gl-m-0" @click="submit">{{
            primaryProps.text
          }}</gl-button>
        </div>
      </div>
    </template>
  </gl-modal>
</template>
