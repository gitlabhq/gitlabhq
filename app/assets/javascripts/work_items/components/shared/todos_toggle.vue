<script>
import { GlButton, GlTooltipDirective, GlAnimatedTodoIcon } from '@gitlab/ui';

import { s__ } from '~/locale';
import { TODO_ADD_ICON, TODO_DONE_ICON } from '../../constants';

export default {
  name: 'TodosToggle',
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
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle'],
  computed: {
    pendingTodo() {
      return this.currentUserTodos.length > 0;
    },
    buttonLabel() {
      return this.pendingTodo ? this.$options.i18n.markAsDone : this.$options.i18n.addATodo;
    },
    buttonIcon() {
      return this.pendingTodo ? TODO_DONE_ICON : TODO_ADD_ICON;
    },
    pendingTodoStateText() {
      return this.pendingTodo ? 'true' : 'false';
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.bottom.hover
    :disabled="isUpdating"
    :title="buttonLabel"
    :category="todosButtonType"
    :selected="pendingTodo"
    class="btn-icon"
    size="small"
    data-testid="todos-toggle"
    :aria-label="buttonLabel"
    :aria-pressed="pendingTodoStateText"
    @click="$emit('toggle')"
  >
    <gl-animated-todo-icon :is-on="pendingTodo" class="gl-button-icon" :name="buttonIcon" />
  </gl-button>
</template>
