<script>
import { GlIcon } from '@gitlab/ui';
import { isNumber } from 'lodash';
import { n__ } from '~/locale';
import { isNotDiffable, stats } from '../utils/diff_file';

export default {
  components: { GlIcon },
  props: {
    diffFile: {
      type: Object,
      required: false,
      default: () => null,
    },
    addedLines: {
      type: Number,
      required: true,
    },
    removedLines: {
      type: Number,
      required: true,
    },
    diffFilesCountText: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    diffFilesLength() {
      return parseInt(this.diffFilesCountText, 10);
    },
    filesText() {
      return n__('file', 'files', this.diffFilesLength);
    },
    isCompareVersionsHeader() {
      return Boolean(this.diffFilesCountText);
    },
    hasDiffFiles() {
      return isNumber(this.diffFilesLength) && this.diffFilesLength >= 0;
    },
    notDiffable() {
      return isNotDiffable(this.diffFile);
    },
    fileStats() {
      return stats(this.diffFile);
    },
  },
};
</script>

<template>
  <div
    class="diff-stats"
    :class="{
      'is-compare-versions-header gl-display-none gl-lg-display-inline-flex': isCompareVersionsHeader,
      'gl-display-none gl-sm-display-inline-flex': !isCompareVersionsHeader,
    }"
  >
    <div v-if="notDiffable" :class="fileStats.classes">
      {{ fileStats.text }}
    </div>
    <div v-else class="diff-stats-contents">
      <div v-if="hasDiffFiles" class="diff-stats-group">
        <gl-icon name="doc-code" class="diff-stats-icon text-secondary" />
        <span class="text-secondary bold">{{ diffFilesCountText }} {{ filesText }}</span>
      </div>
      <div
        class="diff-stats-group gl-text-green-600 gl-display-flex gl-align-items-center"
        :class="{ bold: isCompareVersionsHeader }"
      >
        <span>+</span>
        <span data-testid="js-file-addition-line">{{ addedLines }}</span>
      </div>
      <div
        class="diff-stats-group gl-text-red-500 gl-display-flex gl-align-items-center"
        :class="{ bold: isCompareVersionsHeader }"
      >
        <span>-</span>
        <span data-testid="js-file-deletion-line">{{ removedLines }}</span>
      </div>
    </div>
  </div>
</template>
