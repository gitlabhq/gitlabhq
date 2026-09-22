<script>
import { defineAsyncComponent } from 'vue';
import { debounce } from 'lodash-es';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import LineHighlighter from '~/blob/line_highlighter';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  CODEOWNERS_FILE_NAME,
  BLAME_COLUMN_DEFAULT_WIDTH,
} from './constants';
import Chunk from './components/chunk.vue';
import BlameColumnResizer from './components/blame_column_resizer.vue';
import { hasBlameDataForChunk, normalizeBlameGroups, createBlameSliceBuilder } from './utils';
import blameDataQuery from './queries/blame_data.query.graphql';

export default {
  name: 'SourceViewer',
  components: {
    Chunk,
    BlameColumnResizer,
    CodeownersValidation: defineAsyncComponent(
      () => import('ee_component/blob/components/codeowners_validation.vue'),
    ),
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
      loadingChunks: [], // Which chunks are currently fetching blame data (e.g., [0, 1, 2])
      blameColumnWidth: BLAME_COLUMN_DEFAULT_WIDTH,
    };
  },
  computed: {
    isCodeownersFile() {
      return this.blob.name === CODEOWNERS_FILE_NAME;
    },
    /**
     * Blame groups pre-sliced per chunk, keyed by chunk index. Every blame
     * arrival rebuilds the slices, but a chunk keeps its previous array when
     * its slice is unchanged, so only chunks whose blame moved re-render.
     */
    blameGroupsByChunk() {
      if (!this.showBlame) return {};

      return this.buildBlameSlices(this.chunks, normalizeBlameGroups(this.blameData));
    },
    /**
     * The blame gutter is rendered inside every chunk, so the three tracks are
     * declared once here and each chunk inherits them through `subgrid`. That is
     * what keeps the columns aligned across chunks. The width is also published
     * as a custom property, which is how chunks pin their line numbers just
     * past the gutter.
     */
    blameGridStyling() {
      const blameColumn = this.showBlame ? `${this.blameColumnWidth}px` : '0';
      return {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        gridTemplateColumns: `${blameColumn} auto 1fr`,
        '--blame-column-width': blameColumn,
      };
    },
  },
  watch: {
    shouldPreloadBlame: {
      handler(shouldPreload) {
        if (!shouldPreload) return;
        this.requestBlameInfoForRenderedChunks();
      },
    },
    showBlame: {
      handler(isVisible) {
        if (isVisible) {
          this.renderedChunks.forEach((chunkIndex) => {
            if (!this.loadingChunks.includes(chunkIndex)) this.loadingChunks.push(chunkIndex);
          });
          this.requestBlameInfoForRenderedChunks();
        } else {
          this.loadingChunks = [];
          this.blameData = [];
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
    this.buildBlameSlices = createBlameSliceBuilder();
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
    requestBlameInfoForRenderedChunks() {
      this.renderedChunks.forEach(async (chunkIndex) => {
        const chunk = this.chunks[chunkIndex];
        if (chunk && !hasBlameDataForChunk(this.blameData, chunk)) {
          await this.requestBlameInfo(chunkIndex);
          this.loadingChunks = this.loadingChunks.filter((id) => id !== chunkIndex);
        }
      });
    },
    async handleChunkAppear(chunkIndex, handleOverlappingChunk = true) {
      if (this.renderedChunks.includes(chunkIndex)) return;

      if (chunkIndex > 0 && handleOverlappingChunk) {
        // request the blame information for overlapping chunk in case it is visible in the DOM
        this.handleChunkAppear(chunkIndex - 1, false);
      }

      this.renderedChunks.push(chunkIndex);
      this.loadingChunks.push(chunkIndex);
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
        });

        const blob = data?.project?.repository?.blobs?.nodes[0];
        const blameGroups = blob?.blame?.groups;
        // Duplicates are folded together by `normalizeBlameGroups`, so repeat
        // deliveries of the same group need no guard here.
        if (blameGroups) this.blameData.push(...blameGroups);
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
    <div
      ref="fileContent"
      class="gl-relative gl-isolate gl-flex gl-overflow-x-auto gl-overflow-y-hidden"
    >
      <div
        v-if="showBlame"
        class="gl-pointer-events-none gl-absolute gl-bottom-0 gl-top-0 gl-z-3"
        :style="{ width: `${blameColumnWidth}px` }"
        data-testid="blame-resize-handle"
      >
        <blame-column-resizer v-model="blameColumnWidth" />
      </div>

      <div
        class="file-content code code-syntax-highlight-theme js-syntax-highlight blob-content blob-viewer gl-grid gl-w-full gl-overflow-auto"
        data-type="simple"
        :data-path="blob.path"
        data-testid="blob-viewer-file-content"
        :style="blameGridStyling"
      >
        <codeowners-validation
          v-if="isCodeownersFile"
          class="gl-col-span-3 gl-text-default"
          :current-ref="currentRef"
          :project-path="projectPath"
          :file-path="blob.path"
        />
        <chunk
          v-for="(chunk, index) in chunks"
          :key="index"
          :is-highlighted="Boolean(chunk.isHighlighted)"
          :raw-content="chunk.rawContent"
          :highlighted-content="chunk.highlightedContent"
          :total-lines="chunk.totalLines"
          :starting-from="chunk.startingFrom"
          :blame-path="blob.blamePath"
          :blob-path="blob.path"
          :is-blame-active="showBlame"
          :blame-groups="blameGroupsByChunk[index]"
          :is-blame-loading="loadingChunks.includes(index)"
          @appear="() => handleAppear(index)"
          @disappear="() => handleDisappear(index)"
        />
      </div>
    </div>
  </div>
</template>
