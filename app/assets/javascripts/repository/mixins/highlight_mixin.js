import { nextTick } from 'vue';
import {
  LEGACY_FALLBACKS,
  EVENT_ACTION,
  EVENT_LABEL_FALLBACK,
  LINES_PER_CHUNK,
} from '~/vue_shared/components/source_viewer/constants';
import { splitIntoChunks } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import LineHighlighter from '~/blob/line_highlighter';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import Tracking from '~/tracking';
import { TEXT_FILE_TYPE } from '../constants';

/*
 * This mixin is intended to be used as an interface between our highlight worker and Vue components
 */
export default {
  mixins: [Tracking.mixin()],
  inject: {
    highlightWorker: { default: null },
  },
  data() {
    return {
      chunks: [],
    };
  },
  methods: {
    trackEvent(label, language) {
      this.track(EVENT_ACTION, { label, property: language });
    },
    isUnsupportedLanguage(language) {
      const supportedLanguages = Object.keys(languageLoader);
      const isUnsupportedLanguage = !supportedLanguages.includes(language);

      return LEGACY_FALLBACKS.includes(language) || isUnsupportedLanguage;
    },
    handleUnsupportedLanguage(language) {
      this.trackEvent(EVENT_LABEL_FALLBACK, language);
      this?.onError();
    },
    initHighlightWorker({ rawTextBlob, language, simpleViewer }) {
      if (simpleViewer?.fileType !== TEXT_FILE_TYPE) return;

      if (this.isUnsupportedLanguage(language)) {
        this.handleUnsupportedLanguage(language);
        return;
      }

      /*
       * We want to start rendering content as soon as possible, but highlighting large amounts of
       * content can take long, so we render the content in phases:
       *
       * 1. `splitIntoChunks` with the first 70 lines of raw text.
       *     This ensures that we start rendering raw content in the DOM as soon as we can so that
       *     the user can see content as fast as possible (improves perceived performance and LCP).
       * 2. `instructWorker` to start highlighting the first 70 lines.
       *     This ensures that we display highlighted** content to the user as fast as possible
       *     (improves perceived performance and makes the first 70 lines look nice).
       * 3. `instructWorker` to start highlighting all the content.
       *     This is the longest task. It ensures that we highlight all content, since the first 70
       *     lines are already rendered, this can happen in the background.
       */

      // Render the first 70 lines (raw text) ASAP, this improves perceived performance and LCP.
      const firstSeventyLines = rawTextBlob.split(/\r?\n/).slice(0, LINES_PER_CHUNK).join('\n');

      this.chunks = splitIntoChunks(language, firstSeventyLines);

      this.highlightWorker.onmessage = this.handleWorkerMessage;

      // Instruct the worker to highlight the first 70 lines ASAP, this improves perceived performance.
      this.instructWorker(firstSeventyLines, language);

      // Instruct the worker to start highlighting all lines in the background.
      this.instructWorker(rawTextBlob, language);
    },
    handleWorkerMessage({ data }) {
      this.chunks = data;
      this.highlightHash(); // highlight the line if a line number hash is present in the URL
    },
    instructWorker(content, language) {
      this.highlightWorker.postMessage({ content, language });
    },
    async highlightHash() {
      const { hash } = this.$route;
      if (!hash) return;

      // Make the chunk containing the line number visible
      const lineNumber = hash.substring(hash.indexOf('L') + 1).split('-')[0];
      const chunkToHighlight = this.chunks.find(
        (chunk) =>
          chunk.startingFrom <= lineNumber && chunk.startingFrom + chunk.totalLines >= lineNumber,
      );

      if (chunkToHighlight) {
        chunkToHighlight.isHighlighted = true;
      }

      // Line numbers in the DOM needs to update first based on changes made to `chunks`.
      await nextTick();

      const lineHighlighter = new LineHighlighter({ scrollBehavior: 'auto' });
      lineHighlighter.highlightHash(hash);
    },
  },
};
