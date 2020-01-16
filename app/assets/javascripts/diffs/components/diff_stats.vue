<script>
import { n__ } from '~/locale';

export default {
  props: {
    addedLines: {
      type: Number,
      required: true,
    },
    removedLines: {
      type: Number,
      required: true,
    },
    diffFilesLength: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    filesText() {
      return n__('file', 'files', this.diffFilesLength);
    },
    isCompareVersionsHeader() {
      return Boolean(this.diffFilesLength);
    },
  },
};
</script>

<template>
  <div
    class="diff-stats"
    :class="{
      'is-compare-versions-header d-none d-lg-inline-flex': isCompareVersionsHeader,
      'd-inline-flex': !isCompareVersionsHeader,
    }"
  >
    <div v-if="diffFilesLength !== null" class="diff-stats-group">
      <span class="text-secondary bold">{{ diffFilesLength }} {{ filesText }}</span>
    </div>
    <div
      class="diff-stats-group cgreen d-flex align-items-center"
      :class="{ bold: isCompareVersionsHeader }"
    >
      <span>+</span>
      <span class="js-file-addition-line">{{ addedLines }}</span>
    </div>
    <div
      class="diff-stats-group cred d-flex align-items-center"
      :class="{ bold: isCompareVersionsHeader }"
    >
      <span>-</span>
      <span class="js-file-deletion-line">{{ removedLines }}</span>
    </div>
  </div>
</template>
