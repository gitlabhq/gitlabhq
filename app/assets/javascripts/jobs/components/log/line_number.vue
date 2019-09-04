<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  props: {
    lineNumber: {
      type: Number,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    /**
     * Builds the url for each line number
     *
     * @returns {String}
     */
    buildLineNumber() {
      return `${this.path}#${this.lineNumberId}`;
    },
    /**
     * Array indexes start with 0, so we add 1
     * to create the line number
     *
     * @returns {Number} the line number
     */
    parsedLineNumber() {
      return this.lineNumber + 1;
    },

    /**
     * Creates the anchor for each link
     *
     * @returns {String}
     */
    lineNumberId() {
      return `L${this.parsedLineNumber}`;
    },
  },
};
</script>
<template>
  <gl-link :id="lineNumberId" class="line-number" :href="buildLineNumber">{{
    parsedLineNumber
  }}</gl-link>
</template>
