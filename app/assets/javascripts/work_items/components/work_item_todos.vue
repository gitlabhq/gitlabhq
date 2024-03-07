<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { produce } from 'immer';

import { s__ } from '~/locale';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import createWorkItemTodosMutation from '../graphql/create_work_item_todos.mutation.graphql';
import markDoneWorkItemTodosMutation from '../graphql/mark_done_work_item_todos.mutation.graphql';

import {
  TODO_ADD_ICON,
  TODO_DONE_ICON,
  TODO_PENDING_STATE,
  TODO_DONE_STATE,
  WIDGET_TYPE_CURRENT_USER_TODOS,
} from '../constants';

export default {
  i18n: {
    addATodo: s__('WorkItem|Add a to do'),
    markAsDone: s__('WorkItem|Mark as done'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlButton,
  },
  inject: ['isGroup'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullpath: {
      type: String,
      required: true,
    },
    currentUserTodos: {
      type: Array,
      required: false,
      default: () => [],
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
        targetId: this.workItemId,
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
                // eslint-disable-next-line @gitlab/require-i18n-strings
                __typename: 'Todo',
                id: todo.id,
              });
            }

            this.updateWorkItemCurrentTodosWidgetCache({
              cache,
              todos,
            });
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
    updateWorkItemCurrentTodosWidgetCache({ cache, todos }) {
      const query = {
        query: this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery,
        variables: { fullPath: this.workItemFullpath, iid: this.workItemIid },
      };

      const sourceData = cache.readQuery(query);

      const newData = produce(sourceData, (draftState) => {
        const { widgets } = draftState.workspace.workItems.nodes[0];

        const widgetCurrentUserTodos = widgets.find(
          (widget) => widget.type === WIDGET_TYPE_CURRENT_USER_TODOS,
        );

        widgetCurrentUserTodos.currentUserTodos.nodes = todos;
      });

      cache.writeQuery({ ...query, data: newData });
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    :disabled="isLoading"
    :title="buttonLabel"
    category="secondary"
    class="btn-icon"
    :aria-label="buttonLabel"
    @click="onToggle"
  >
    <gl-icon :class="{ 'gl-fill-blue-500': pendingTodo }" :name="buttonIcon" />
  </gl-button>
</template>
