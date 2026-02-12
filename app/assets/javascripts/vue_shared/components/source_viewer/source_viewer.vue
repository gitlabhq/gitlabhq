<script>
import { debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import LineHighlighter from '~/blob/line_highlighter';
import { EVENT_ACTION, EVENT_LABEL_VIEWER, CODEOWNERS_FILE_NAME } from './constants';
import Chunk from './components/chunk.vue';
import BlameInfo from './components/blame_info.vue';
import {
  calculateBlameOffset,
  shouldRender,
  toggleBlameLineBorders,
  hasBlameDataForChunk,
} from './utils';
import blameDataQuery from './queries/blame_data.query.graphql';
import BlameSkeletonLoader from './components/blame_skeleton_loader.vue';

export default {
  name: 'SourceViewer',
  components: {
    Chunk,
    BlameInfo,
    BlameSkeletonLoader,
    CodeownersValidation: () => import('ee_component/blob/components/codeowners_validation.vue'),
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  i18n: {
    blameErrorMessage: __('Unable to load blame information. Please try again.'),
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
    chunks: {
      type: Array,
      required: false,
      default: () => [],
    },
    shouldPreloadBlame: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBlame: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectPath: {
      type: String,
      required: true,
    },
    currentRef: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      lineHighlighter: new LineHighlighter(),
      blameData: [],
      renderedChunks: [],
      isBlameLoading: false,
      loadingChunks: [], // Which chunks are currently fetching blame data (e.g., [0, 1, 2])
      chunkOffsets: {}, // Vertical position of each chunk (e.g., { 0: 0, 1: 450, 2: 900 })
    };
  },
  computed: {
    blameInfo() {
      return this.blameData.reduce((result, blame, index) => {
        if (shouldRender(this.blameData, index)) {
          result.push({
            ...blame,
            blameOffset: calculateBlameOffset(blame.lineno, index),
          });
        }

        return result;
      }, []);
    },
    isCodeownersFile() {
      return this.blob.name === CODEOWNERS_FILE_NAME;
    },
    /**
     * Filters out chunks that already have blame data loaded,
     * so skeleton loaders only show for chunks still fetching.
     */
    activeLoadingChunks() {
      if (!this.showBlame) return [];

      return this.loadingChunks.filter((chunkIndex) => {
        const chunk = this.chunks[chunkIndex];
        return chunk && !hasBlameDataForChunk(this.blameData, chunk);
      });
    },
  },
  watch: {
    shouldPreloadBlame: {
      handler(shouldPreload) {
        if (!shouldPreload) return;
        this.requestBlameInfo(this.renderedChunks[0]);
      },
    },
    showBlame: {
      async handler(isVisible) {
        toggleBlameLineBorders(this.blameData, isVisible);

        if (isVisible) {
          this.isBlameLoading = true;
          this.renderedChunks.forEach((chunkIndex) => {
            if (!this.loadingChunks.includes(chunkIndex)) this.loadingChunks.push(chunkIndex);
          });
          await this.updateChunkOffsets(this.renderedChunks);
        } else {
          this.isBlameLoading = false;
          this.loadingChunks = [];
          this.blameData = [];
        }

        this.requestBlameInfo(this.renderedChunks[0]);
      },
      immediate: true,
    },
    blameData: {
      async handler(blameData) {
        if (!this.showBlame) return;
        toggleBlameLineBorders(blameData, true);

        if (blameData.length > 0) {
          this.isBlameLoading = false;

          // Reposition skeleton loaders after new blame data affects layout
          await this.updateChunkOffsets(this.activeLoadingChunks);
        }
      },
      immediate: true,
    },
    chunks: {
      handler() {
        this.selectLine();
      },
    },
  },
  mounted() {
    this.selectLine();
  },
  created() {
    this.pendingChunks = new Set();
    this.processPendingChunks = debounce(() => {
      this.pendingChunks.forEach((index) => this.handleChunkAppear(index));
      this.pendingChunks.clear();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    this.track(EVENT_ACTION, { label: EVENT_LABEL_VIEWER, property: this.blob.language });
    addBlobLinksTracking();
  },
  beforeDestroy() {
    this.pendingChunks.clear();
    this.processPendingChunks.cancel?.();
  },
  methods: {
    async handleChunkAppear(chunkIndex, handleOverlappingChunk = true) {
      if (this.renderedChunks.includes(chunkIndex)) return;

      if (chunkIndex > 0 && handleOverlappingChunk) {
        // request the blame information for overlapping chunk incase it is visible in the DOM
        this.handleChunkAppear(chunkIndex - 1, false);
      }

      this.renderedChunks.push(chunkIndex);
      this.loadingChunks.push(chunkIndex);
      await this.updateChunkOffsets([chunkIndex]);
      await this.requestBlameInfo(chunkIndex);
      this.loadingChunks = this.loadingChunks.filter((id) => id !== chunkIndex);
    },
    async requestBlameInfo(chunkIndex) {
      const chunk = this.chunks[chunkIndex];
      if ((!this.showBlame && !this.shouldPreloadBlame) || !chunk) return;

      try {
        const { data } = await this.$apollo.query({
          query: blameDataQuery,
          variables: {
            ref: this.currentRef,
            fullPath: this.projectPath,
            filePath: this.blob.path,
            fromLine: chunk.startingFrom + 1,
            toLine: chunk.startingFrom + chunk.totalLines,
            ignoreRevs: parseBoolean(getParameterByName('ignore_revs')),
          },
          context: { batchKey: 'blameData' },
        });

        const blob = data?.project?.repository?.blobs?.nodes[0];
        const blameGroups = blob?.blame?.groups;
        const isDuplicate = this.blameData.includes(blameGroups[0]);
        if (blameGroups && !isDuplicate) this.blameData.push(...blameGroups);
      } catch (error) {
        const errorMessage =
          error.graphQLErrors?.[0]?.message || this.$options.i18n.blameErrorMessage;
        createAlert({
          message: errorMessage,
          parent: this.$refs.fileContent?.parentElement,
          dismissible: false,
          captureError: true,
          error,
        });
      }
    },
    async selectLine() {
      await this.$nextTick();
      this.lineHighlighter.highlightHash(this.$route.hash);
    },
    async updateChunkOffsets(chunkIndices) {
      await this.$nextTick();
      const newOffsets = { ...this.chunkOffsets };
      chunkIndices.forEach((chunkIndex) => {
        const chunkEl = this.$refs[`chunk-${chunkIndex}`]?.[0]?.$el;
        if (chunkEl) newOffsets[chunkIndex] = chunkEl.offsetTop;
      });

      this.chunkOffsets = newOffsets;
    },

    handleAppear(chunkIndex) {
      // Queue visible chunks to prevent skipping during rapid scrolling
      this.pendingChunks.add(chunkIndex);
      this.processPendingChunks();
    },
    handleDisappear(chunkIndex) {
      // Prevent chunk from processing if it's not visible in the DOM
      this.pendingChunks.delete(chunkIndex);
    },
  },
};
</script>

<template>
  <div>
    <div class="flash-container gl-mb-3"></div>
    <div ref="fileContent" class="gl-relative gl-flex">
      <blame-info v-if="showBlame" :blame-info="blameInfo" :project-path="projectPath" />

      <blame-skeleton-loader
        v-for="chunkIndex in activeLoadingChunks"
        :key="`loading-${chunkIndex}`"
        :total-lines="1"
        class="gl-absolute gl-left-0"
        :style="{ transform: `translateY(${chunkOffsets[chunkIndex] || 0}px)` }"
      />

      <div
        class="file-content code code-syntax-highlight-theme js-syntax-highlight blob-content blob-viewer gl-flex gl-w-full gl-flex-col gl-overflow-auto"
        data-type="simple"
        :data-path="blob.path"
        data-testid="blob-viewer-file-content"
      >
        <codeowners-validation
          v-if="isCodeownersFile"
          class="gl-text-default"
          :current-ref="currentRef"
          :project-path="projectPath"
          :file-path="blob.path"
        />
        <chunk
          v-for="(chunk, index) in chunks"
          :key="index"
          :ref="`chunk-${index}`"
          :is-highlighted="Boolean(chunk.isHighlighted)"
          :raw-content="chunk.rawContent"
          :highlighted-content="chunk.highlightedContent"
          :total-lines="chunk.totalLines"
          :starting-from="chunk.startingFrom"
          :blame-path="blob.blamePath"
          :blob-path="blob.path"
          @appear="() => handleAppear(index)"
          @disappear="() => handleDisappear(index)"
        />
      </div>
    </div>
  </div>
</template>
