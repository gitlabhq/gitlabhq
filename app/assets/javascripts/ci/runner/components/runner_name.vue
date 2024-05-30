<script>
import { formatRunnerName } from '../utils';

export default {
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    name() {
      return formatRunnerName(this.runner);
    },
  },
};
</script>
<template>
  <span class="gl-font-bold gl-align-middle">{{ name }}</span>
</template>
