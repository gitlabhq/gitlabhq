<script>
import { GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import CommitInfo from '~/repository/components/commit_info.vue';
import { calculateBlameOffset, toggleBlameClasses } from '../utils';

export default {
  name: 'BlameInfo',
  components: {
    CommitInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    blameData: {
      type: Array,
      required: true,
    },
  },
  computed: {
    blameInfo() {
      return this.blameData.map((blame, index) => ({
        ...blame,
        blameOffset: calculateBlameOffset(blame.lineno, index),
      }));
    },
  },
  watch: {
    blameData: {
      handler(blameData) {
        toggleBlameClasses(blameData, true);
      },
      immediate: true,
    },
  },
  destroyed() {
    toggleBlameClasses(this.blameData, false);
  },
};
</script>
<template>
  <div class="blame gl-bg-gray-10">
    <div class="blame-commit gl-border-none!">
      <commit-info
        v-for="(blame, index) in blameInfo"
        :key="index"
        :class="{ 'gl-border-t': index !== 0 }"
        class="gl-display-flex gl-absolute gl-px-3"
        :style="{ top: blame.blameOffset }"
        :commit="blame.commit"
      />
    </div>
  </div>
</template>
