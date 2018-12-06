<script>
import { sprintf, __ } from '~/locale';

export default {
  props: {
    aMode: {
      type: String,
      required: false,
      default: null,
    },
    bMode: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    outputText() {
      return sprintf(__('File mode changed from %{a_mode} to %{b_mode}'), {
        a_mode: this.aMode,
        b_mode: this.bMode,
      });
    },
  },
};
</script>

<template>
  <div class="nothing-here-block">{{ outputText }}</div>
</template>
