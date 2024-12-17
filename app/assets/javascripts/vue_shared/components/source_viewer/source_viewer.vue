<script>
import { debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import LineHighlighter from '~/blob/line_highlighter';
import { EVENT_ACTION, EVENT_LABEL_VIEWER, CODEOWNERS_FILE_NAME } from './constants';
import Chunk from './components/chunk.vue';
import Blame from './components/blame_info.vue';
import { calculateBlameOffset, shouldRender, toggleBlameClasses } from './utils';
import blameDataQuery from './queries/blame_data.query.graphql';

export default {
  name: 'SourceViewer',
  components: {
    Chunk,
    Blame,
    CodeownersValidation: () => import('ee_component/blob/components/codeowners_validation.vue'),
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
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
  },
  watch: {
    showBlame: {
      handler(isVisible) {
        toggleBlameClasses(this.blameData, isVisible);
        this.requestBlameInfo(this.renderedChunks[0]);
      },
      immediate: true,
    },
    blameData: {
      handler(blameData) {
        if (!this.showBlame) return;
        toggleBlameClasses(blameData, true);
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
    this.handleAppear = debounce(this.handleChunkAppear, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    this.track(EVENT_ACTION, { label: EVENT_LABEL_VIEWER, property: this.blob.language });
    addBlobLinksTracking();
  },
  methods: {
    async handleChunkAppear(chunkIndex, handleOverlappingChunk = true) {
      if (!this.renderedChunks.includes(chunkIndex)) {
        this.renderedChunks.push(chunkIndex);
        await this.requestBlameInfo(chunkIndex);

        if (chunkIndex > 0 && handleOverlappingChunk) {
          // request the blame information for overlapping chunk incase it is visible in the DOM
          this.handleChunkAppear(chunkIndex - 1, false);
        }
      }
    },
    async requestBlameInfo(chunkIndex) {
      const chunk = this.chunks[chunkIndex];
      if (!this.showBlame || !chunk) return;

      const { data } = await this.$apollo.query({
        query: blameDataQuery,
        variables: {
          ref: this.currentRef,
          fullPath: this.projectPath,
          filePath: this.blob.path,
          fromLine: chunk.startingFrom + 1,
          toLine: chunk.startingFrom + chunk.totalLines,
        },
      });

      const blob = data?.project?.repository?.blobs?.nodes[0];
      const blameGroups = blob?.blame?.groups;
      const isDuplicate = this.blameData.includes(blameGroups[0]);
      if (blameGroups && !isDuplicate) this.blameData.push(...blameGroups);
    },
    async selectLine() {
      await this.$nextTick();
      this.lineHighlighter.highlightHash(this.$route.hash);
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div class="gl-flex">
    <blame v-if="showBlame && blameInfo.length" :blame-info="blameInfo" />

    <div
      class="file-content code js-syntax-highlight blob-content blob-viewer gl-flex gl-w-full gl-flex-col gl-overflow-auto"
      :class="$options.userColorScheme"
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
        :chunk-index="index"
        :is-highlighted="Boolean(chunk.isHighlighted)"
        :raw-content="chunk.rawContent"
        :highlighted-content="chunk.highlightedContent"
        :total-lines="chunk.totalLines"
        :starting-from="chunk.startingFrom"
        :blame-path="blob.blamePath"
        :blob-path="blob.path"
        @appear="() => handleAppear(index)"
      />
    </div>
  </div>
</template>
