<script>
import { n__ } from '~/locale';

export default {
  name: 'FileRowStats',
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    addedLinesLabel() {
      return n__('%d line added', '%d lines added', this.file.addedLines);
    },
    removedLinesLabel() {
      return n__('%d line removed', '%d lines removed', this.file.removedLines);
    },
  },
};
</script>

<template>
  <span
    class="file-row-stats gl-inline-flex gl-gap-2 gl-text-sm gl-font-semibold gl-tracking-tight"
  >
    <span
      v-if="file.addedLines"
      data-testid="file-added-lines"
      class="gl-text-success"
      :aria-label="addedLinesLabel"
    >
      +{{ file.addedLines }}
    </span>
    <span
      v-if="file.removedLines"
      data-testid="file-removed-lines"
      class="gl-text-danger"
      :aria-label="removedLinesLabel"
    >
      -{{ file.removedLines }}
    </span>
  </span>
</template>
