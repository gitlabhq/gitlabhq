<script>
import { GlButton, GlTooltipDirective, GlAnimatedTodoIcon } from '@gitlab/ui';

import { s__ } from '~/locale';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import createWorkItemTodosMutation from '../../graphql/create_work_item_todos.mutation.graphql';
import markDoneWorkItemTodosMutation from '../../graphql/mark_done_work_item_todos.mutation.graphql';

import {
  TODO_ADD_ICON,
  TODO_DONE_ICON,
  TODO_PENDING_STATE,
  TODO_DONE_STATE,
} from '../../constants';

export default {
  i18n: {
    addATodo: s__('WorkItem|Add a to-do item'),
    markAsDone: s__('WorkItem|Mark as done'),
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
      let mutation = createWorkItemTodosMutation;
      let inputVariables = {
        targetId: this.itemId,
      };
      if (this.pendingTodo) {
        mutation = markDoneWorkItemTodosMutation;
        inputVariables = {
          id: this.todoId,
        };
      }

      this.$apollo
        .mutate({
          mutation,
          variables: {
            input: inputVariables,
          },
          optimisticResponse: {
            todoMutation: {
              todo: {
                id: this.todoId,
                state: this.pendingTodo ? TODO_DONE_STATE : TODO_PENDING_STATE,
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
            if (this.pendingTodo) {
              updateGlobalTodoCount(1);
              this.buttonLabel = this.$options.i18n.markAsDone;
            } else {
              updateGlobalTodoCount(-1);
              this.buttonLabel = this.$options.i18n.addATodo;
            }
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
      :class="{ '!gl-text-blue-500': pendingTodo }"
      :name="buttonIcon"
    />
  </gl-button>
</template>
