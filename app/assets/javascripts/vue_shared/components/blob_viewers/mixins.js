import { SNIPPET_MEASURE_BLOBS_CONTENT } from '~/performance_constants';
import eventHub from '~/blob/components/eventhub';

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
    eventHub.$emit(SNIPPET_MEASURE_BLOBS_CONTENT);
  },
};
