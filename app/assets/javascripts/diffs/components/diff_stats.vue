<script>
import Icon from '~/vue_shared/components/icon.vue';
import { n__ } from '~/locale';
import { isNumber } from 'lodash';

export default {
  components: { Icon },
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
      'd-inline-flex': !isCompareVersionsHeader,
    }"
  >
    <div v-if="hasDiffFiles" class="diff-stats-group">
      <icon name="doc-code" class="diff-stats-icon text-secondary" />
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
