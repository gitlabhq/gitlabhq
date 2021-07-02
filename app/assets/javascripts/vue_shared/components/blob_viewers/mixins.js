import eventHub from '~/blob/components/eventhub';
import { SNIPPET_MEASURE_BLOBS_CONTENT } from '~/performance/constants';

export default {
  props: {
    content: {
      type: String,
      required: false,
      default: null,
    },
    richViewer: {
      type: String,
      default: '',
      required: false,
    },
    type: {
      type: String,
      required: true,
    },
    isRawContent: {
      type: Boolean,
      default: false,
      required: false,
    },
    fileName: {
      type: String,
      required: false,
      default: '',
    },
  },
  mounted() {
    eventHub.$emit(SNIPPET_MEASURE_BLOBS_CONTENT);
  },
};
