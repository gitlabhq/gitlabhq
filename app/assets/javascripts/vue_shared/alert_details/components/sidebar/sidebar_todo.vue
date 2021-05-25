<script>
import produce from 'immer';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import { s__ } from '~/locale';
import Todo from '~/sidebar/components/todo_toggle/todo.vue';
import createAlertTodoMutation from '../../graphql/mutations/alert_todo_create.mutation.graphql';
import alertQuery from '../../graphql/queries/alert_sidebar_details.query.graphql';

export default {
  i18n: {
    UPDATE_ALERT_TODO_ERROR: s__(
      'AlertManagement|There was an error while updating the to-do item of the alert.',
    ),
  },
  components: {
    Todo,
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
    sidebarCollapsed: {
      type: Boolean,
      required: true,
    },
  },
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
    getAlertQueryVariables() {
      return {
        fullPath: this.projectPath,
        alertId: this.alert.iid,
      };
    },
  },
  methods: {
    updateToDoCount(add) {
      const oldCount = parseInt(document.querySelector('.js-todos-count').innerText, 10);
      const count = add ? oldCount + 1 : oldCount - 1;
      const headerTodoEvent = new CustomEvent('todo:toggle', {
        detail: {
          count,
        },
      });

      return document.dispatchEvent(headerTodoEvent);
    },
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
            return this.throwError(errors[0]);
          }
          return this.updateToDoCount(true);
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
            return this.throwError(errors[0]);
          }
          return this.updateToDoCount(false);
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
    throwError(err = '') {
      const error = err || s__('AlertManagement|Please try again.');
      this.$emit('alert-error', `${this.$options.i18n.UPDATE_ALERT_TODO_ERROR} ${error}`);
    },
  },
};
</script>

<template>
  <div
    :class="{
      'block todo': sidebarCollapsed,
      'gl-ml-auto': !sidebarCollapsed,
    }"
  >
    <todo
      data-testid="alert-todo-button"
      :collapsed="sidebarCollapsed"
      :issuable-id="alertID"
      :is-todo="hasPendingTodos"
      :is-action-active="isUpdating"
      issuable-type="alert"
      @toggleTodo="hasPendingTodos ? markAsDone() : addToDo()"
    />
  </div>
</template>
