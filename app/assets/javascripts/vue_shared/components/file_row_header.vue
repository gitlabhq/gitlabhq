<script>
import { truncatePathMiddleToLength } from '~/lib/utils/text_utility';

const MAX_PATH_LENGTH = 40;

export default {
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    truncatedPath() {
      return truncatePathMiddleToLength(this.path, MAX_PATH_LENGTH);
    },
  },
};
</script>

<template>
  <div class="file-row-header bg-white sticky-top p-2 js-file-row-header">
    <span class="bold">{{ truncatedPath }}</span>
  </div>
</template>
