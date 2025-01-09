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
    diffsCount: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    diffFilesLength() {
      return parseInt(this.diffsCount, 10);
    },
    filesText() {
      return n__('file', 'files', this.diffFilesLength);
    },
    isCompareVersionsHeader() {
      return Boolean(this.diffsCount);
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
      'is-compare-versions-header gl-hidden lg:gl-inline-flex': isCompareVersionsHeader,
      'gl-hidden sm:!gl-inline-flex': !isCompareVersionsHeader,
    }"
  >
    <div v-if="notDiffable" :class="fileStats.classes">
      {{ fileStats.text }}
    </div>
    <div v-else class="diff-stats-contents">
      <div v-if="hasDiffFiles" class="diff-stats-group">
        <gl-icon name="doc-code" class="diff-stats-icon" variant="subtle" />
        <span class="gl-font-bold gl-text-subtle">{{ diffsCount }} {{ filesText }}</span>
      </div>
      <div
        class="diff-stats-group gl-flex gl-items-center gl-text-success"
        :class="{ 'gl-font-bold': isCompareVersionsHeader }"
      >
        <span>+</span>
        <span data-testid="js-file-addition-line">{{ addedLines }}</span>
      </div>
      <div
        class="diff-stats-group gl-flex gl-items-center gl-text-danger"
        :class="{ 'gl-font-bold': isCompareVersionsHeader }"
      >
        <span>−</span>
        <span data-testid="js-file-deletion-line">{{ removedLines }}</span>
      </div>
    </div>
  </div>
</template>
