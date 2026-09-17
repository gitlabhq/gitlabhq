<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlIntersectionObserver } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, sprintf } from '~/locale';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';
import { addInteractionClass } from '~/code_navigation/utils';
import { findOverlayElementFromPoint } from '../utils';
import { BLAME_AGE_COLORS } from '../constants';
import BlameCommitInfo from './blame_commit_info.vue';
import BlameSkeletonLoader from './blame_skeleton_loader.vue';

/*
 * We only highlight the chunk that is currently visible to the user.
 * By making use of the Intersection Observer API we can determine when a chunk becomes visible and highlight it accordingly.
 *
 * Content that is not visible to the user (i.e. not highlighted) does not need to look nice,
 * so by rendering raw (non-highlighted) text, the browser spends less resources on painting
 * content that is not immediately relevant.
 * Why use plaintext as opposed to hiding content entirely?
 * If content is hidden entirely, native find text (⌘ + F) won't work.
 */
export default {
  name: 'SourceViewerChunk',
  components: {
    GlIntersectionObserver,
    BlameCommitInfo,
    BlameSkeletonLoader,
  },
  directives: {
    SafeHtml,
  },
  inject: ['blameActions', 'glFeatures'],
  props: {
    isHighlighted: {
      type: Boolean,
      required: true,
    },
    rawContent: {
      type: String,
      required: true,
    },
    highlightedContent: {
      type: String,
      required: true,
    },
    totalLines: {
      type: Number,
      required: false,
      default: 0,
    },
    startingFrom: {
      type: Number,
      required: false,
      default: 0,
    },
    blamePath: {
      type: String,
      required: true,
    },
    blobPath: {
      type: String,
      required: true,
    },
    isBlameActive: {
      type: Boolean,
      required: false,
      default: false,
    },
    blameGroups: {
      type: Array,
      required: false,
      default: () => [],
    },
    isBlameLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['appear', 'disappear'],
  data() {
    return {
      number: undefined,
      hasAppeared: false,
    };
  },
  computed: {
    ...mapState(['data', 'blobs']),
    shouldHighlight() {
      return Boolean(this.highlightedContent) && (this.hasAppeared || this.isHighlighted);
    },
    pageSearchString() {
      const page = getPageParamValue(this.number);
      return getPageSearchString(this.blamePath, page);
    },
    // Pin the raw `<code>` to `totalLines` × line-height so the in-flow layer
    // matches the overlay and the overlay's trailing box can't overhang
    // into `.file-content` (which would spawn a spurious second scrollbar).
    rawCodeStyling() {
      return { minHeight: `calc(${this.totalLines} * var(--source-line-height))` };
    },
    // The chunk's rows have to be explicit: `row-span-full` is `1 / -1`, and
    // `-1` resolves against the explicit grid, so with rows left implicit the
    // full-height layers (gutter background, skeleton, code) collapse to line 1.
    chunkGridStyling() {
      return { gridTemplateRows: `repeat(${this.totalLines}, var(--source-line-height))` };
    },
    showBlameSkeleton() {
      return this.isBlameActive && this.isBlameLoading && !this.blameGroups.length;
    },
    blameSeparatorRows() {
      return this.blameGroups.filter((group) => group.hasSeparator).map((group) => group.rowStart);
    },
  },
  watch: {
    shouldHighlight: {
      handler(newVal) {
        if (!this.blobs?.length) return;

        if (newVal) {
          if (this.data) {
            this.addCodeNavigationClasses();
          } else {
            // If the code navigation hasn't loaded yet we need to watch
            // for the data to be set in the state
            this.codeNavigationDataWatcher = this.$watch('data', () => {
              this.addCodeNavigationClasses();
              this.codeNavigationDataWatcher();
            });
          }
        }
      },
      immediate: true,
    },
  },
  created() {
    // Kept off `data` so Vue doesn't take over the gutter cell's class attribute,
    // which would wipe the selection classes LineHighlighter adds to it.
    this.hoveredGutter = null;
    this.hoverFrameId = null;
    this.pendingHover = null;
  },
  beforeDestroy() {
    if (this.hoverFrameId) cancelAnimationFrame(this.hoverFrameId);
  },
  methods: {
    handleChunkAppear() {
      this.hasAppeared = true;
      this.$emit('appear');
    },
    // Forward a raw-layer pointer event to the hljs span at the same coords.
    forwardEventToHighlight({ type, clientX, clientY }) {
      const overlay = this.$refs.highlightOverlay;
      if (!overlay) return;
      const target = findOverlayElementFromPoint(overlay, clientX, clientY);
      if (target) target.dispatchEvent(new MouseEvent(type, { bubbles: true, clientX, clientY }));
    },
    calculateLineNumber(index) {
      return this.startingFrom + index + 1;
    },
    blameCellStyling(group) {
      return {
        gridRowStart: group.rowStart,
        gridRowEnd: group.rowStart + group.rowSpan,
        '--blame-age-color': BLAME_AGE_COLORS[group.commitData?.ageMapClass] || 'transparent',
      };
    },
    // Reads `rowStart`, not `lineno`: a group carried over from the previous
    // chunk keeps its original `lineno`, but this cell covers only the lines
    // clamped into this chunk.
    blameCellLabel({ rowStart, rowSpan }) {
      const start = this.startingFrom + rowStart;
      const end = start + rowSpan - 1;

      return start === end
        ? sprintf(s__('Blame|Line %{start}'), { start })
        : sprintf(s__('Blame|Lines %{start} to %{end}'), { start, end });
    },
    rowStyling(row) {
      return { gridRow: row };
    },
    lineNumberStyling(row) {
      return { ...this.rowStyling(row), left: 'var(--blame-column-width)' };
    },
    // Tints the gutter cell of the line the cursor is over in the code content.
    // `mousemove` fires very frequently, so the hit-test runs at most once per
    // animation frame, on the latest cursor position.
    handleCodeHover({ clientX, clientY }) {
      this.pendingHover = { clientX, clientY };
      if (this.hoverFrameId) return;

      this.hoverFrameId = requestAnimationFrame(() => {
        this.hoverFrameId = null;
        this.resolveHoveredGutter();
      });
    },
    // The raw layer is a single element, so the line comes from the overlay.
    resolveHoveredGutter() {
      const overlay = this.$refs.highlightOverlay;
      if (!overlay || !this.pendingHover) return;

      const { clientX, clientY } = this.pendingHover;
      const target = findOverlayElementFromPoint(overlay, clientX, clientY);
      const line = target?.closest?.('.line[id^="LC"]');
      this.setHoveredGutter(line ? Number(line.id.replace('LC', '')) : null);
    },
    clearHoveredGutter() {
      if (this.hoverFrameId) {
        cancelAnimationFrame(this.hoverFrameId);
        this.hoverFrameId = null;
      }
      this.setHoveredGutter(null);
    },
    // Toggled imperatively rather than with `:class`, see `hoveredGutter` above.
    setHoveredGutter(lineNumber) {
      const gutter =
        lineNumber != null
          ? this.$el.querySelector(`#L${lineNumber}`)?.closest('.diff-line-num')
          : null;

      if (gutter === this.hoveredGutter) return;

      this.hoveredGutter?.classList.remove('is-over');
      gutter?.classList.add('is-over');
      this.hoveredGutter = gutter;
    },
    handleBlameClick(event, index) {
      if (this.glFeatures.inlineBlame) {
        event.preventDefault();
        this.blameActions.activateInlineBlame(this.calculateLineNumber(index));
      }
    },
    async addCodeNavigationClasses() {
      await this.$nextTick();

      Object.keys(this.data[this.blobPath]).forEach((key) => {
        const startLine = Number(key.split(':')[0]);

        if (startLine >= this.startingFrom && startLine < this.startingFrom + this.totalLines + 1) {
          addInteractionClass({
            path: this.blobPath,
            d: this.data[this.blobPath][key],
          });
        }
      });
    },
  },
};
</script>
<template>
  <div class="gl-col-span-3 gl-grid gl-grid-cols-subgrid" :style="chunkGridStyling">
    <template v-if="isBlameActive">
      <!--
        Column 1 is pinned so the resize handle, anchored outside the scroller,
        keeps matching its edge. This layer backs the cells: it covers lines
        with no blame group yet, and hides code scrolling underneath.
      -->
      <div
        class="gl-border-r gl-sticky gl-left-0 gl-z-2 gl-col-start-1 gl-row-span-full gl-bg-subtle"
        aria-hidden="true"
      ></div>

      <blame-skeleton-loader
        v-if="showBlameSkeleton"
        class="gl-sticky gl-left-0 gl-z-2 gl-col-start-1 gl-row-span-full"
        :start-line="startingFrom"
        :total-lines="totalLines"
      />

      <div
        v-for="group in blameGroups"
        :key="`blame-${group.lineno}`"
        class="blame-age-indicator gl-sticky gl-left-0 gl-z-2 gl-col-start-1 gl-select-none gl-overflow-hidden gl-px-3"
        :style="blameCellStyling(group)"
        data-testid="blame-cell"
      >
        <span class="gl-sr-only" data-testid="blame-cell-lines">{{ blameCellLabel(group) }}</span>
        <blame-commit-info
          :commit="group.commit"
          :previous-blame-path="group.commitData && group.commitData.previousBlamePath"
        />
      </div>

      <!--
        Separates consecutive blame blocks. Split in two because the gutter
        follows the page theme while the code follows the syntax theme, so no
        single border colour reads correctly across both. The code half is not
        sticky, so it slides over the gutter on horizontal scroll; it is drawn
        first so the sticky gutter half covers it there.
      -->
      <template v-for="rowStart in blameSeparatorRows">
        <div
          :key="`separator-code-${rowStart}`"
          class="gl-border-t gl-pointer-events-none gl-z-4 gl-col-span-2 gl-col-start-2 -gl-mt-px gl-border-t-gray-500"
          :style="rowStyling(rowStart)"
          aria-hidden="true"
          data-testid="blame-separator"
        ></div>
        <div
          :key="`separator-gutter-${rowStart}`"
          class="gl-border-t gl-pointer-events-none gl-sticky gl-left-0 gl-z-4 gl-col-start-1 -gl-mt-px"
          :style="rowStyling(rowStart)"
          aria-hidden="true"
          data-testid="blame-separator-gutter"
        ></div>
      </template>
    </template>

    <template v-if="shouldHighlight">
      <div
        v-for="(n, index) in totalLines"
        :key="index"
        data-testid="line-numbers"
        class="diff-line-num line-links line-numbers gl-border-r gl-sticky gl-z-3 gl-col-start-2 gl-flex !gl-p-0"
        :style="lineNumberStyling(index + 1)"
      >
        <a
          v-if="!isBlameActive"
          class="file-line-blame gl-select-none !gl-shadow-none"
          data-event-tracking="click_chunk_blame_on_blob_page"
          :href="`${blamePath}${pageSearchString}#L${calculateLineNumber(index)}`"
          :aria-label="`View blame for line ${calculateLineNumber(index)}`"
          :data-testid="`blame-link-${calculateLineNumber(index)}`"
          @click="handleBlameClick($event, index)"
        ></a>
        <a
          :id="`L${calculateLineNumber(index)}`"
          class="file-line-num gl-select-none !gl-shadow-none"
          :href="`#L${calculateLineNumber(index)}`"
          :data-line-number="calculateLineNumber(index)"
        >
          {{ calculateLineNumber(index) }}
        </a>
      </div>
    </template>

    <!-- Placeholder holding the gutter column open while content is not highlighted -->
    <div
      v-else
      class="line-numbers gl-col-start-2 gl-row-span-full !gl-p-0 gl-text-transparent"
    ></div>

    <gl-intersection-observer
      class="gl-col-start-3 gl-row-span-full gl-w-full"
      @appear="handleChunkAppear"
      @disappear="() => $emit('disappear')"
    >
      <pre
        class="code highlight gl-relative gl-m-0 gl-w-full !gl-overflow-visible !gl-border-none !gl-p-0 gl-leading-0"
      ><code v-once class="line gl-relative gl-z-1 !gl-whitespace-pre !gl-bg-transparent !gl-text-transparent" :style="rawCodeStyling" data-testid="content" @click="forwardEventToHighlight" @mouseover="forwardEventToHighlight" @mouseout="forwardEventToHighlight" @mousemove="handleCodeHover" @mouseleave="clearHoveredGutter" v-text="rawContent"></code><code v-if="shouldHighlight" ref="highlightOverlay" v-safe-html="highlightedContent" class="gl-absolute gl-left-0" data-gfm-ignore inert></code></pre>
    </gl-intersection-observer>
  </div>
</template>
