<script>
import { s__ } from '~/locale';
import Todo from '~/sidebar/components/todo_toggle/todo.vue';
import axios from '~/lib/utils/axios_utils';
import createAlertTodo from '../../graphql/mutations/alert_todo_create.graphql';

export default {
  i18n: {
    UPDATE_ALERT_TODO_ERROR: s__(
      'AlertManagement|There was an error while updating the To Do of the alert.',
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
      isTodo: false,
      todo: '',
    };
  },
  computed: {
    alertID() {
      return parseInt(this.alert.iid, 10);
    },
  },
  methods: {
    updateToDoCount(add) {
      const oldCount = parseInt(document.querySelector('.todos-count').innerText, 10);
      const count = add ? oldCount + 1 : oldCount - 1;
      const headerTodoEvent = new CustomEvent('todo:toggle', {
        detail: {
          count,
        },
      });

      return document.dispatchEvent(headerTodoEvent);
    },
    toggleTodo() {
      if (this.todo) {
        return this.markAsDone();
      }

      this.isUpdating = true;
      return this.$apollo
        .mutate({
          mutation: createAlertTodo,
          variables: {
            iid: this.alert.iid,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { alertTodoCreate: { todo = {}, errors = [] } } = {} } = {}) => {
          if (errors[0]) {
            return this.$emit(
              'alert-error',
              `${this.$options.i18n.UPDATE_ALERT_TODO_ERROR} ${errors[0]}.`,
            );
          }

          this.todo = todo.id;
          return this.updateToDoCount(true);
        })
        .catch(() => {
          this.$emit(
            'alert-error',
            `${this.$options.i18n.UPDATE_ALERT_TODO_ERROR} ${s__(
              'AlertManagement|Please try again.',
            )}`,
          );
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    markAsDone() {
      this.isUpdating = true;

      return axios
        .delete(`/dashboard/todos/${this.todo.split('/').pop()}`)
        .then(() => {
          this.todo = '';
          return this.updateToDoCount(false);
        })
        .catch(() => {
          this.$emit('alert-error', this.$options.i18n.UPDATE_ALERT_TODO_ERROR);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <div :class="{ 'block todo': sidebarCollapsed, 'gl-ml-auto': !sidebarCollapsed }">
    <todo
      data-testid="alert-todo-button"
      :collapsed="sidebarCollapsed"
      :issuable-id="alertID"
      :is-todo="todo !== ''"
      :is-action-active="isUpdating"
      issuable-type="alert"
      @toggleTodo="toggleTodo"
    />
  </div>
</template>
