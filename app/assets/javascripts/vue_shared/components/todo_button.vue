<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

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
      return this.isTodo ? __('Mark as done') : __('Add a To Do');
    },
  },
};
</script>

<template>
  <gl-button v-bind="$attrs" :aria-label="buttonLabel" @click="$emit('click', $event)">
    {{ buttonLabel }}
  </gl-button>
</template>
