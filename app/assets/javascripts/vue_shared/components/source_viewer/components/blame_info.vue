<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import AccessorUtilities from '~/lib/utils/accessor';
import AccessiblePanelResizer from '~/vue_shared/components/accessible_panel_resizer.vue';
import { calculateBlameOffset } from '../utils';
import BlameCommitInfo from './blame_commit_info.vue';

export default {
  name: 'BlameInfo',
  i18n: {
    resizeLabel: __('Resize blame column'),
  },
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
    BlameCommitInfo,
    AccessiblePanelResizer,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  resizer: {
    blameInfoColumnDefaultWidth: 400,
    blameInfoColumnMaxWidth: 600,
    blameInfoColumnMinWidth: 250,
    blameInfoWidthStorageKey: 'blame-column-width',
  },
  props: {
    blameInfo: {
      type: Array,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isDesktop: PanelBreakpointInstance.isDesktop(),
      containerHeight: 0,
      containerWidth: this.$options.resizer.blameInfoColumnDefaultWidth,
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
    PanelBreakpointInstance.addResizeListener(this.handlePanelResize);

    this.updateContainerHeight();
    this.restoreBlameColumnWidth();
  },
  beforeDestroy() {
    PanelBreakpointInstance.removeResizeListener(this.handlePanelResize);
  },
  methods: {
    handlePanelResize() {
      this.isDesktop = PanelBreakpointInstance.isDesktop();
      this.restoreBlameColumnWidth();
    },
    restoreBlameColumnWidth() {
      if (!this.isDesktop) {
        this.containerWidth = this.$options.resizer.blameInfoColumnMinWidth;
        return;
      }

      if (!AccessorUtilities.canUseLocalStorage()) return;

      const userPreference = localStorage.getItem(this.$options.resizer.blameInfoWidthStorageKey);
      this.containerWidth =
        parseInt(userPreference, 10) || this.$options.resizer.blameInfoColumnDefaultWidth;
    },
    onResize(value) {
      this.containerWidth = value ?? this.$options.resizer.blameInfoColumnDefaultWidth;
    },
    onResizeEnd(value) {
      if (!AccessorUtilities.canUseLocalStorage()) return;
      localStorage.setItem(this.$options.resizer.blameInfoWidthStorageKey, value);
    },
    calculateCommitHeight(commitInfo, nextCommitInfo) {
      const currentOffset = parseInt(commitInfo.blameOffset, 10) || 0;
      const { lineno, span } = commitInfo;

      // Bound the indicator to this group's range. If its end line is in an
      // unloaded chunk, render nothing rather than spanning across the gap.
      if (span) {
        const groupEndOffset = calculateBlameOffset(lineno + span);
        if (groupEndOffset === null) return 0;
        return Math.max(parseInt(groupEndOffset, 10) - currentOffset, 0);
      }

      if (!nextCommitInfo) return this.containerHeight - currentOffset;

      const nextOffset = parseInt(nextCommitInfo.blameOffset, 10) || 0;
      return Math.max(nextOffset - currentOffset, 0);
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
  <div class="blame gl-border-r gl-bg-subtle" :style="{ width: `${containerWidth}px` }">
    <accessible-panel-resizer
      v-if="isDesktop"
      side="right"
      :aria-label="$options.i18n.resizeLabel"
      :value="containerWidth"
      :default-size="$options.resizer.blameInfoColumnDefaultWidth"
      :min-size="$options.resizer.blameInfoColumnMinWidth"
      :max-size="$options.resizer.blameInfoColumnMaxWidth"
      @input="onResize"
      @resize-end="onResizeEnd"
    />

    <div class="blame-commit !gl-border-none">
      <template v-if="blameInfo.length">
        <span
          v-for="(processedBlame, index) in processedBlameInfo"
          :key="`indicator-${index}`"
          :ref="`indicator-${index}`"
          class="blame-commit-wrapper"
          :style="processedBlame.style"
          aria-hidden="true"
        ></span>
      </template>

      <template v-if="blameInfo.length">
        <blame-commit-info
          v-for="(blame, index) in blameInfo"
          :key="index"
          :class="{ 'gl-border-t': blame.blameOffset !== '0px' }"
          class="gl-absolute gl-flex gl-px-3"
          :style="{ top: blame.blameOffset }"
          :commit="blame.commit"
          :span="blame.span"
          :previous-path="blame.previousPath"
          :project-path="projectPath"
        />
      </template>
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
