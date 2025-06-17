<script>
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { isNumber } from 'lodash';
import { n__ } from '~/locale';
import { isNotDiffable, stats } from '../utils/diff_file';

export default {
  components: { GlIcon, GlSprintf },
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
      type: [String, Number],
      required: false,
      default: null,
    },
    hideOnNarrowScreen: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    diffFilesLength() {
      return parseInt(this.diffsCount, 10);
    },
    filesText() {
      return n__('%{count} file', '%{count} files', this.diffFilesLength);
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
    statsLabel() {
      const counters = [];
      if (this.addedLines > 0)
        counters.push(
          n__('RapidDiffs|Added %d line.', 'RapidDiffs|Added %d lines.', this.addedLines),
        );
      if (this.removedLines > 0)
        counters.push(
          n__('RapidDiffs|Removed %d line.', 'RapidDiffs|Removed %d lines.', this.removedLines),
        );
      return counters.join(' ');
    },
  },
};
</script>

<template>
  <div
    class="diff-stats"
    :class="{
      'is-compare-versions-header gl-hidden lg:gl-inline-flex':
        isCompareVersionsHeader && hideOnNarrowScreen,
      'gl-hidden sm:!gl-inline-flex': !isCompareVersionsHeader && hideOnNarrowScreen,
      'gl-inline-flex': !hideOnNarrowScreen,
    }"
  >
    <div v-if="notDiffable" :class="fileStats.classes">
      {{ fileStats.text }}
    </div>
    <div v-else class="diff-stats-contents">
      <div v-if="hasDiffFiles" class="diff-stats-group">
        <gl-icon name="doc-code" class="diff-stats-icon" variant="subtle" />
        <span class="gl-font-bold gl-text-subtle">
          <gl-sprintf :message="filesText">
            <template #count>{{ diffsCount }}</template>
          </gl-sprintf>
        </span>
      </div>
      <div class="gl-flex" :aria-label="statsLabel">
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
  </div>
</template>
