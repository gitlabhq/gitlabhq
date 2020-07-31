import {
  SNIPPET_MARK_VIEW_APP_START,
  SNIPPET_MARK_BLOBS_CONTENT,
  SNIPPET_MEASURE_BLOBS_CONTENT,
  SNIPPET_MEASURE_BLOBS_CONTENT_WITHIN_APP,
} from '~/performance_constants';

export default {
  props: {
    content: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  mounted() {
    window.requestAnimationFrame(() => {
      if (!performance.getEntriesByName(SNIPPET_MARK_BLOBS_CONTENT).length) {
        performance.mark(SNIPPET_MARK_BLOBS_CONTENT);
        performance.measure(SNIPPET_MEASURE_BLOBS_CONTENT);
        performance.measure(SNIPPET_MEASURE_BLOBS_CONTENT_WITHIN_APP, SNIPPET_MARK_VIEW_APP_START);
      }
    });
  },
};
