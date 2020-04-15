<script>
import { DEFAULT_HEADING } from '../constants';

export default {
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    heading() {
      return this.title || DEFAULT_HEADING;
    },
  },
};
</script>
<template>
  <div>
    <h3 ref="sseHeading">{{ heading }}</h3>
  </div>
</template>
