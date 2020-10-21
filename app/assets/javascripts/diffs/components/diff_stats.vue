<script>
import { isNumber } from 'lodash';
import { GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  components: { GlIcon },
  props: {
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
  },
};
</script>

<template>
  <div
    class="diff-stats"
    :class="{
      'is-compare-versions-header d-none d-lg-inline-flex': isCompareVersionsHeader,
      'd-none d-sm-inline-flex': !isCompareVersionsHeader,
    }"
  >
    <div v-if="hasDiffFiles" class="diff-stats-group">
      <gl-icon name="doc-code" class="diff-stats-icon text-secondary" />
      <span class="text-secondary bold">{{ diffFilesCountText }} {{ filesText }}</span>
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
