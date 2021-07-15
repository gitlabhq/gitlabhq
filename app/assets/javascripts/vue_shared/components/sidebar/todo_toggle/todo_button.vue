<script>
import { GlButton } from '@gitlab/ui';
import { todoLabel } from './utils';

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
  },
  computed: {
    buttonLabel() {
      return todoLabel(this.isTodo);
    },
  },
  methods: {
    updateGlobalTodoCount(additionalTodoCount) {
      const countContainer = document.querySelector('.js-todos-count');
      if (countContainer === null) return;
      const currentCount = parseInt(countContainer.innerText, 10);
      const todoToggleEvent = new CustomEvent('todo:toggle', {
        detail: {
          count: Math.max(currentCount + additionalTodoCount, 0),
        },
      });

      document.dispatchEvent(todoToggleEvent);
    },
    incrementGlobalTodoCount() {
      this.updateGlobalTodoCount(1);
    },
    decrementGlobalTodoCount() {
      this.updateGlobalTodoCount(-1);
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
  <gl-button v-bind="$attrs" :aria-label="buttonLabel" @click="onToggle($event)">
    {{ buttonLabel }}
  </gl-button>
</template>
