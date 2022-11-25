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
      updateGlobalTodoCount(-1);
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
