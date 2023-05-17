<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import { getWorkItemTodoOptimisticResponse } from '../utils';
import { ADD, MARK_AS_DONE, TODO_ADD_ICON, TODO_DONE_ICON } from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';

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
  props: {
    workItem: {
      type: Object,
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
    pendingTodo() {
      return this.currentUserTodos.length > 0;
    },
    buttonIcon() {
      return this.pendingTodo ? TODO_DONE_ICON : TODO_ADD_ICON;
    },
  },
  methods: {
    onToggle() {
      this.isLoading = true;
      this.buttonLabel = '';
      const action = this.pendingTodo ? MARK_AS_DONE : ADD;
      const inputVariables = {
        id: this.workItem.id,
        currentUserTodosWidget: {
          action,
        },
      };
      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: inputVariables,
          },
          optimisticResponse: getWorkItemTodoOptimisticResponse({
            workItem: this.workItem,
            pendingTodo: this.pendingTodo,
          }),
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
    v-gl-tooltip.hover
    data-testid="work-item-todos-action"
    :loading="isLoading"
    :title="buttonLabel"
    category="tertiary"
    :aria-label="buttonLabel"
    @click="onToggle"
  >
    <gl-icon
      data-testid="work-item-todos-icon"
      :class="{ 'gl-fill-blue-500': pendingTodo }"
      :name="buttonIcon"
    />
  </gl-button>
</template>
