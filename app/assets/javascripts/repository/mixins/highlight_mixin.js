import {
  LEGACY_FALLBACKS,
  EVENT_ACTION,
  EVENT_LABEL_FALLBACK,
  LINES_PER_CHUNK,
  ROUGE_TO_HLJS_LANGUAGE_MAP,
} from '~/vue_shared/components/source_viewer/constants';
import { splitIntoChunks } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import Tracking from '~/tracking';
import axios from '~/lib/utils/axios_utils';
import { TEXT_FILE_TYPE } from '../constants';

/*
 * This mixin is intended to be used as an interface between our highlight worker and Vue components
 */
export default {
  HLJS_MAX_SIZE: 2000000, // 2MB
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
      const mappedLanguage = ROUGE_TO_HLJS_LANGUAGE_MAP[language];
      const supportedLanguages = Object.keys(languageLoader);
      const isUnsupportedLanguage = !supportedLanguages.includes(mappedLanguage);

      return LEGACY_FALLBACKS.includes(language) || isUnsupportedLanguage;
    },
    handleUnsupportedLanguage(language) {
      this.trackEvent(EVENT_LABEL_FALLBACK, language);
      this?.onError();
    },
    async handleLFSBlob(externalStorageUrl, rawPath, language) {
      await axios
        .get(externalStorageUrl || rawPath)
        .then(({ data }) => this.instructWorker(data, language))
        .catch(() => this.$emit('error'));
    },
    initHighlightWorker(blob, isUsingLfs) {
      const { rawTextBlob, name, fileType, externalStorageUrl, rawPath, simpleViewer } = blob;
      let { language } = blob;

      if (name.endsWith('.gleam')) {
        language = 'gleam';
      }

      if (simpleViewer?.fileType !== TEXT_FILE_TYPE) return;

      if (this.isUnsupportedLanguage(language)) {
        this.handleUnsupportedLanguage(language);
        return;
      }

      this.highlightWorker.onmessage = this.handleWorkerMessage;

      if (isUsingLfs) {
        this.handleLFSBlob(externalStorageUrl, rawPath, language);
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

      // Instruct the worker to highlight the first 70 lines ASAP, this improves perceived performance.
      this.instructWorker(firstSeventyLines, language);

      // Instruct the worker to start highlighting all lines in the background.
      this.instructWorker(rawTextBlob, language, fileType);
    },
    handleWorkerMessage({ data }) {
      // If the current length of chunks is bigger, it means we've highlighted the whole file already, so nothing to be done here
      if (data.length < this.chunks.length) return;
      this.chunks = data;
      this.highlightHash(); // highlight the line if a line number hash is present in the URL
    },
    instructWorker(content, language, fileType) {
      this.highlightWorker.postMessage({ content, language, fileType });
    },
    highlightHash() {
      const { hash } = this.$route;
      if (!hash) return;

      const [fromLineNumber, toLineNumber] = hash.substring(hash.indexOf('L') + 1).split('-');
      const isInRange = ({ startingFrom, totalLines }, lineNumber) =>
        startingFrom <= lineNumber && startingFrom + totalLines >= lineNumber;

      this.chunks.map((chunk) => {
        const formattedChunk = chunk;
        const totalLineSpan = chunk.startingFrom + chunk.totalLines;
        if (
          fromLineNumber >= chunk.startingFrom ||
          totalLineSpan <= toLineNumber ||
          isInRange(chunk, toLineNumber)
        ) {
          formattedChunk.isHighlighted = true; // Make the chunk containing the line number visible
        }

        return formattedChunk;
      });
    },
  },
};
