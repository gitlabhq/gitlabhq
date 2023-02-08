<script>
import { GlLoadingIcon } from '@gitlab/ui';
import LineHighlighter from '~/blob/line_highlighter';
import eventHub from '~/notes/event_hub';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import Tracking from '~/tracking';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  EVENT_LABEL_FALLBACK,
  ROUGE_TO_HLJS_LANGUAGE_MAP,
  LINES_PER_CHUNK,
  LEGACY_FALLBACKS,
} from './constants';
import Chunk from './components/chunk_deprecated.vue';
import { registerPlugins } from './plugins/index';

/*
 * This component is optimized to handle source code with many lines of code by splitting source code into chunks of 70 lines of code,
 * we highlight and display the 1st chunk (L1-70) to the user as quickly as possible.
 *
 * The rest of the lines (L71+) is rendered once the browser goes into an idle state (requestIdleCallback).
 * Each chunk is self-contained, this ensures when for example the width of a container on line 1000 changes,
 * it does not trigger a repaint on a parent element that wraps all 1000 lines.
 */
export default {
  components: {
    GlLoadingIcon,
    Chunk,
  },
  mixins: [Tracking.mixin()],
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      languageDefinition: null,
      content: this.blob.rawTextBlob,
      language: ROUGE_TO_HLJS_LANGUAGE_MAP[this.blob.language?.toLowerCase()],
      hljs: null,
      firstChunk: null,
      chunks: {},
      isLoading: true,
      isLineSelected: false,
      lineHighlighter: null,
    };
  },
  computed: {
    splitContent() {
      return this.content.split(/\r?\n/);
    },
    lineNumbers() {
      return this.splitContent.length;
    },
    unsupportedLanguage() {
      const supportedLanguages = Object.keys(languageLoader);
      const unsupportedLanguage =
        !supportedLanguages.includes(this.language) &&
        !supportedLanguages.includes(this.blob.language?.toLowerCase());

      return LEGACY_FALLBACKS.includes(this.language) || unsupportedLanguage;
    },
    totalChunks() {
      return Object.keys(this.chunks).length;
    },
  },
  async created() {
    addBlobLinksTracking();
    this.trackEvent(EVENT_LABEL_VIEWER);

    if (this.unsupportedLanguage) {
      this.handleUnsupportedLanguage();
      return;
    }

    this.generateFirstChunk();
    this.hljs = await this.loadHighlightJS();

    if (this.language) {
      this.languageDefinition = await this.loadLanguage();
    }

    // Highlight the first chunk as soon as highlight.js is available
    this.highlightChunk(null, true);

    window.requestIdleCallback(async () => {
      // Generate the remaining chunks once the browser idles to ensure the browser resources are spent on the most important things first
      this.generateRemainingChunks();
      this.isLoading = false;
      await this.$nextTick();
      this.lineHighlighter = new LineHighlighter({ scrollBehavior: 'auto' });
    });
  },
  methods: {
    trackEvent(label) {
      this.track(EVENT_ACTION, { label, property: this.blob.language });
    },
    handleUnsupportedLanguage() {
      this.trackEvent(EVENT_LABEL_FALLBACK);
      this.$emit('error');
    },
    generateFirstChunk() {
      const lines = this.splitContent.splice(0, LINES_PER_CHUNK);
      this.firstChunk = this.createChunk(lines);
    },
    generateRemainingChunks() {
      const result = {};
      for (let i = 0; i < this.splitContent.length; i += LINES_PER_CHUNK) {
        const chunkIndex = Math.floor(i / LINES_PER_CHUNK);
        const lines = this.splitContent.slice(i, i + LINES_PER_CHUNK);
        result[chunkIndex] = this.createChunk(lines, i + LINES_PER_CHUNK);
      }

      this.chunks = result;
    },
    createChunk(lines, startingFrom = 0) {
      return {
        content: lines.join('\n'),
        startingFrom,
        totalLines: lines.length,
        language: this.language,
        isHighlighted: false,
      };
    },
    highlightChunk(index, isFirstChunk) {
      const chunk = isFirstChunk ? this.firstChunk : this.chunks[index];

      if (chunk.isHighlighted) {
        return;
      }

      const { highlightedContent, language } = this.highlight(chunk.content, this.language);

      Object.assign(chunk, { language, content: highlightedContent, isHighlighted: true });

      this.selectLine();

      this.$nextTick(() => eventHub.$emit('showBlobInteractionZones', this.blob.path));
    },
    highlight(content, language) {
      let detectedLanguage = language;
      let highlightedContent;
      if (this.hljs) {
        registerPlugins(this.hljs, this.blob.fileType, this.content);
        if (!detectedLanguage) {
          const hljsHighlightAuto = this.hljs.highlightAuto(content);
          highlightedContent = hljsHighlightAuto.value;
          detectedLanguage = hljsHighlightAuto.language;
        } else if (this.languageDefinition) {
          highlightedContent = this.hljs.highlight(content, { language: this.language }).value;
        }
      }

      return { highlightedContent, language: detectedLanguage };
    },
    loadHighlightJS() {
      // If no language can be mapped to highlight.js we load all common languages else we load only the core (smallest footprint)
      return !this.language ? import('highlight.js/lib/common') : import('highlight.js/lib/core');
    },
    async loadLanguage() {
      let languageDefinition;

      try {
        languageDefinition = await languageLoader[this.language]();
        this.hljs.registerLanguage(this.language, languageDefinition.default);
      } catch (message) {
        this.$emit('error', message);
      }

      return languageDefinition;
    },
    async selectLine() {
      if (this.isLineSelected || !this.lineHighlighter) {
        return;
      }

      this.isLineSelected = true;
      await this.$nextTick();
      this.lineHighlighter.highlightHash(this.$route.hash);
    },
  },
  userColorScheme: window.gon.user_color_scheme,
  currentlySelectedLine: null,
};
</script>
<template>
  <div
    class="file-content code js-syntax-highlight blob-content gl-display-flex gl-flex-direction-column gl-overflow-auto"
    :class="$options.userColorScheme"
    data-type="simple"
    :data-path="blob.path"
    data-qa-selector="blob_viewer_file_content"
  >
    <chunk
      v-if="firstChunk"
      :lines="firstChunk.lines"
      :total-lines="firstChunk.totalLines"
      :content="firstChunk.content"
      :starting-from="firstChunk.startingFrom"
      :is-highlighted="firstChunk.isHighlighted"
      is-first-chunk
      :language="firstChunk.language"
      :blame-path="blob.blamePath"
    />

    <gl-loading-icon v-if="isLoading" size="sm" class="gl-my-5" />
    <chunk
      v-for="(chunk, key, index) in chunks"
      v-else
      :key="key"
      :lines="chunk.lines"
      :content="chunk.content"
      :total-lines="chunk.totalLines"
      :starting-from="chunk.startingFrom"
      :is-highlighted="chunk.isHighlighted"
      :chunk-index="index"
      :language="chunk.language"
      :blame-path="blob.blamePath"
      :total-chunks="totalChunks"
      @appear="highlightChunk"
    />
  </div>
</template>
