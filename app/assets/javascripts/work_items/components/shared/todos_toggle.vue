<script>
import { GlButton, GlTooltipDirective, GlAnimatedTodoIcon } from '@gitlab/ui';

import { s__ } from '~/locale';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import createWorkItemTodosMutation from '../../graphql/create_work_item_todos.mutation.graphql';
import updateWorkItemCurrentUserTodosMutation from '../../graphql/update_work_item_current_user_todos.mutation.graphql';

import { TODO_ADD_ICON, TODO_DONE_ICON, TODO_PENDING_STATE } from '../../constants';

export default {
  i18n: {
    addATodo: s__('WorkItem|Add a to-do item'),
    markAsDone: s__('WorkItem|Mark to-do items done'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlAnimatedTodoIcon,
  },
  props: {
    itemId: {
      type: String,
      required: true,
    },
    currentUserTodos: {
      type: Array,
      required: false,
      default: () => [],
    },
    todosButtonType: {
      type: String,
      required: false,
      default: 'tertiary',
    },
  },
  data() {
    return {
      isLoading: false,
      buttonLabel:
        this.currentUserTodos.length > 0
          ? this.$options.i18n.markAsDone
          : this.$options.i18n.addATodo,
    };
  },
  computed: {
    todoId() {
      return this.currentUserTodos[0]?.id || '';
    },
    todoCount() {
      return this.currentUserTodos.length;
    },
    pendingTodo() {
      return this.todoId !== '';
    },
    buttonIcon() {
      return this.pendingTodo ? TODO_DONE_ICON : TODO_ADD_ICON;
    },
  },
  methods: {
    onToggle() {
      this.isLoading = true;
      this.buttonLabel = '';
      const isMarkingDone = this.pendingTodo;
      const todosBeingMarkedDone = this.todoCount;

      if (isMarkingDone) {
        this.markAllTodosDone(todosBeingMarkedDone);
      } else {
        this.createTodo();
      }
    },
    createTodo() {
      this.$apollo
        .mutate({
          mutation: createWorkItemTodosMutation,
          variables: {
            input: {
              targetId: this.itemId,
            },
          },
          optimisticResponse: {
            todoMutation: {
              todo: {
                id: this.todoId,
                state: TODO_PENDING_STATE,
              },
              errors: [],
            },
          },
          update: (
            cache,
            {
              data: {
                todoMutation: { todo = {} },
              },
            },
          ) => {
            const todos = [];
            if (todo.state === TODO_PENDING_STATE) {
              todos.push({
                __typename: 'Todo',
                id: todo.id,
              });
            }
            this.$emit('todosUpdated', { cache, todos });
          },
        })
        .then(
          ({
            data: {
              todoMutation: { errors },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }
            updateGlobalTodoCount(1);
            this.buttonLabel = this.$options.i18n.markAsDone;
          },
        )
        .catch((error) => {
          this.$emit('error', error.message);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    markAllTodosDone(todoCount) {
      this.$apollo
        .mutate({
          mutation: updateWorkItemCurrentUserTodosMutation,
          variables: {
            input: {
              id: this.itemId,
              currentUserTodosWidget: {
                action: 'MARK_AS_DONE',
              },
            },
          },
          update: (cache) => {
            this.$emit('todosUpdated', { cache, todos: [] });
          },
        })
        .then(
          ({
            data: {
              workItemUpdate: { errors },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }
            updateGlobalTodoCount(-todoCount);
            this.buttonLabel = this.$options.i18n.addATodo;
          },
        )
        .catch((error) => {
          this.$emit('error', error.message);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.bottom.hover
    :disabled="isLoading"
    :title="buttonLabel"
    :category="todosButtonType"
    class="btn-icon"
    :aria-label="buttonLabel"
    @click="onToggle"
  >
    <gl-animated-todo-icon
      :is-on="pendingTodo"
      :class="{ '!gl-text-status-info': pendingTodo }"
      class="gl-button-icon"
      :name="buttonIcon"
    />
  </gl-button>
</template>
