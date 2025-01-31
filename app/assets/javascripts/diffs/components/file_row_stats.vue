<script>
import { n__ } from '~/locale';

export default {
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
  <span class="file-row-stats">
    <span data-testid="file-added-lines" class="gl-text-success" :aria-label="addedLinesLabel">
      +{{ file.addedLines }}
    </span>
    <span data-testid="file-removed-lines" class="gl-text-danger" :aria-label="removedLinesLabel">
      -{{ file.removedLines }}
    </span>
  </span>
</template>

<style>
.file-row-stats {
  font-size: 12px;
}
</style>
