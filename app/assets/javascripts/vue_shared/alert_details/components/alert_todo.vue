<script>
import produce from 'immer';
import { GlButton, GlTooltipDirective, GlAnimatedTodoIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import createAlertTodoMutation from '../graphql/mutations/alert_todo_create.mutation.graphql';
import alertQuery from '../graphql/queries/alert_sidebar_details.query.graphql';

const MARK_TEXT = __('Mark to-do items done');
const TODO_TEXT = __('Add a to-do item');

export default {
  name: 'AlertTodo',
  i18n: {
    UPDATE_ALERT_TODO_ERROR: s__(
      'AlertManagement|There was an error while updating the to-do item of the alert.',
    ),
  },
  components: {
    GlButton,
    GlAnimatedTodoIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    alert: {
      type: Object,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  emits: ['alert-error'],
  data() {
    return {
      isUpdating: false,
    };
  },
  computed: {
    alertID() {
      return parseInt(this.alert.iid, 10);
    },
    firstToDoId() {
      return this.alert?.todos?.nodes[0]?.id;
    },
    hasPendingTodos() {
      return this.alert?.todos?.nodes.length > 0;
    },
    buttonLabel() {
      return this.hasPendingTodos ? MARK_TEXT : TODO_TEXT;
    },
    getAlertQueryVariables() {
      return {
        fullPath: this.projectPath,
        alertId: this.alert.iid,
      };
    },
  },
  methods: {
    addToDo() {
      this.isUpdating = true;
      return this.$apollo
        .mutate({
          mutation: createAlertTodoMutation,
          variables: {
            iid: this.alert.iid,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { errors = [] } }) => {
          if (errors[0]) {
            this.throwError(errors[0]);
            return;
          }
          updateGlobalTodoCount(1);
        })
        .catch(() => {
          this.throwError();
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    markAsDone() {
      this.isUpdating = true;
      return this.$apollo
        .mutate({
          mutation: todoMarkDoneMutation,
          variables: {
            id: this.firstToDoId,
          },
          update: this.updateCache,
        })
        .then(({ data: { errors = [] } }) => {
          if (errors[0]) {
            this.throwError(errors[0]);
            return;
          }
          updateGlobalTodoCount(-1);
        })
        .catch(() => {
          this.throwError();
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    updateCache(store) {
      const sourceData = store.readQuery({
        query: alertQuery,
        variables: this.getAlertQueryVariables,
      });

      const data = produce(sourceData, (draftData) => {
        draftData.project.alertManagementAlerts.nodes[0].todos.nodes = [];
      });

      store.writeQuery({
        query: alertQuery,
        variables: this.getAlertQueryVariables,
        data,
      });
    },
    handleButtonClick() {
      if (this.hasPendingTodos) {
        this.markAsDone();
      } else {
        this.addToDo();
      }
    },
    throwError(err = '') {
      const error = err || s__('AlertManagement|Please try again.');
      this.$emit('alert-error', `${this.$options.i18n.UPDATE_ALERT_TODO_ERROR} ${error}`);
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.bottom.hover
    data-testid="alert-todo-button"
    :disabled="isUpdating"
    :title="buttonLabel"
    class="btn-icon"
    :aria-label="buttonLabel"
    :data-issuable-id="alertID"
    data-issuable-type="alert"
    @click="handleButtonClick"
  >
    <gl-animated-todo-icon
      :is-on="hasPendingTodos"
      :class="{ '!gl-text-status-info': hasPendingTodos }"
      class="gl-button-icon"
      :name="hasPendingTodos ? 'todo-done' : 'todo-add'"
    />
  </gl-button>
</template>
