<script>
import { GlButton } from '@gitlab/ui';
import { todoLabel, updateGlobalTodoCount } from '../../utils';

export default {
  components: {
    GlButton,
  },
  props: {
    isTodo: {
      type: Boolean,
      required: false,
      default: true,
    },
    isIconButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    todoCount: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  computed: {
    buttonLabel() {
      return todoLabel(this.isTodo);
    },
  },
  methods: {
    incrementGlobalTodoCount() {
      updateGlobalTodoCount(1);
    },
    decrementGlobalTodoCount() {
      updateGlobalTodoCount(-this.todoCount);
    },
    onToggle(event) {
      if (this.isTodo) {
        this.decrementGlobalTodoCount();
      } else {
        this.incrementGlobalTodoCount();
      }
      this.$emit('click', event);
    },
  },
};
</script>

<template>
  <gl-button
    v-bind="$attrs"
    :aria-label="buttonLabel"
    :class="{ 'btn-icon': isIconButton }"
    @click="onToggle($event)"
  >
    <slot>{{ buttonLabel }}</slot>
  </gl-button>
</template>
