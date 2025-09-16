<script>
import { GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import CommitInfo from '~/repository/components/commit_info.vue';

export default {
  name: 'BlameInfo',
  BLAME_AGE_COLORS: {
    'blame-commit-age-0': 'var(--gl-color-data-blue-900)',
    'blame-commit-age-1': 'var(--gl-color-data-blue-800)',
    'blame-commit-age-2': 'var(--gl-color-data-blue-700)',
    'blame-commit-age-3': 'var(--gl-color-data-blue-600)',
    'blame-commit-age-4': 'var(--gl-color-data-blue-500)',
    'blame-commit-age-5': 'var(--gl-color-data-blue-400)',
    'blame-commit-age-6': 'var(--gl-color-data-blue-300)',
    'blame-commit-age-7': 'var(--gl-color-data-blue-200)',
    'blame-commit-age-8': 'var(--gl-color-data-blue-100)',
    'blame-commit-age-9': 'var(--gl-color-data-blue-50)',
  },
  components: {
    CommitInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    blameInfo: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      containerHeight: 0,
    };
  },
  computed: {
    processedBlameInfo() {
      return this.blameInfo.map((blame, index) => {
        const ageClass = blame.commitData?.ageMapClass ?? '';
        const indicatorColor = this.$options.BLAME_AGE_COLORS[ageClass] || 'transparent';

        const height = this.calculateCommitHeight(blame, this.blameInfo[index + 1]);

        return {
          ...blame,
          style: {
            '--blame-indicator-top': blame.blameOffset,
            '--blame-indicator-color': indicatorColor,
            '--blame-indicator-height': `${height}px`,
          },
        };
      });
    },
  },
  watch: {
    blameInfo: {
      handler() {
        this.$nextTick(() => {
          this.updateContainerHeight();
        });
      },
      deep: true,
    },
  },
  mounted() {
    this.updateContainerHeight();
  },
  methods: {
    calculateLastItemHeight(currentOffset) {
      return this.containerHeight - currentOffset;
    },
    calculateCommitHeight(commitInfo, nextCommitInfo) {
      const currentOffset = parseInt(commitInfo.blameOffset, 10) || 0;

      if (!nextCommitInfo) {
        return this.calculateLastItemHeight(currentOffset);
      }

      const nextOffset = parseInt(nextCommitInfo.blameOffset, 10) || 0;
      const calculatedHeight = nextOffset - currentOffset;

      return calculatedHeight > 0 ? calculatedHeight : 0;
    },
    updateContainerHeight() {
      if (this.$el) {
        this.containerHeight = this.$el.offsetHeight;
      }
    },
  },
};
</script>
<template>
  <div class="blame gl-border-r gl-bg-subtle">
    <div class="blame-commit !gl-border-none">
      <span
        v-for="(processedBlame, index) in processedBlameInfo"
        :key="`indicator-${index}`"
        :ref="`indicator-${index}`"
        class="blame-commit-wrapper"
        :style="processedBlame.style"
      ></span>
      <commit-info
        v-for="(blame, index) in blameInfo"
        :key="index"
        :class="{ 'gl-border-t': blame.blameOffset !== '0px' }"
        class="gl-absolute gl-flex gl-px-3"
        :style="{ top: blame.blameOffset }"
        :commit="blame.commit"
        :span="blame.span"
        :prev-blame-link="blame.commitData && blame.commitData.projectBlameLink"
      />
    </div>
  </div>
</template>

<style scoped>
.blame-commit-wrapper::before {
  content: '';
  position: absolute;
  left: 0;
  top: var(--blame-indicator-top);
  height: var(--blame-indicator-height);
  width: 3px;
  background-color: var(--blame-indicator-color);
  pointer-events: none;
}
</style>
