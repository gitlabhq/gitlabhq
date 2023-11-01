<script>
import { debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import LineHighlighter from '~/blob/line_highlighter';
import { EVENT_ACTION, EVENT_LABEL_VIEWER } from './constants';
import Chunk from './components/chunk_new.vue';
import Blame from './components/blame_info.vue';
import { calculateBlameOffset, shouldRender, toggleBlameClasses } from './utils';
import blameDataQuery from './queries/blame_data.query.graphql';

/*
 * Note, this is a new experimental version of the SourceViewer, it is not ready for production use.
 * See the following issue for more details: https://gitlab.com/gitlab-org/gitlab/-/issues/391586
 */

export default {
  name: 'SourceViewerNew',
  components: {
    Chunk,
    Blame,
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
  },
  data() {
    return {
      lineHighlighter: new LineHighlighter(),
      blameData: [],
      renderedChunks: [],
      overlappingBlameRequested: false,
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
  },
  watch: {
    showBlame: {
      handler(shouldShow) {
        toggleBlameClasses(this.blameData, shouldShow);
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
  },
  created() {
    this.handleAppear = debounce(this.handleChunkAppear, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    this.track(EVENT_ACTION, { label: EVENT_LABEL_VIEWER, property: this.blob.language });
    addBlobLinksTracking();
  },
  mounted() {
    this.selectLine();
  },
  methods: {
    async handleChunkAppear(chunkIndex) {
      const chunk = this.chunks[chunkIndex];

      if (!this.renderedChunks.includes(chunkIndex)) {
        this.renderedChunks.push(chunkIndex);

        const { data } = await this.$apollo.query({
          query: blameDataQuery,
          variables: {
            fullPath: this.projectPath,
            filePath: this.blob.path,
            fromLine: chunk.startingFrom + 1,
            toLine: chunk.startingFrom + chunk.totalLines,
          },
        });

        const blob = data?.project?.repository?.blobs?.nodes[0];
        const blameGroups = blob?.blame?.groups;
        if (blameGroups) this.blameData.push(...blameGroups);
        if (chunkIndex > 0 && !this.overlappingBlameRequested) {
          // request the blame information for overlapping chunk incase it is visible in the DOM
          this.handleChunkAppear(chunkIndex - 1);
          this.overlappingBlameRequested = true;
        }
      }
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
  <div class="gl-display-flex">
    <blame v-if="showBlame && blameInfo.length" :blame-info="blameInfo" />

    <div
      class="file-content code js-syntax-highlight blob-content gl-display-flex gl-flex-direction-column gl-overflow-auto gl-w-full"
      :class="$options.userColorScheme"
      data-type="simple"
      :data-path="blob.path"
    >
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
        @appear="() => handleAppear(index)"
      />
    </div>
  </div>
</template>
