<script>
import { formatRunnerName } from '../utils';

export default {
  name: 'RunnerName',
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
  <span class="gl-align-middle gl-font-bold">{{ name }}</span>
</template>
