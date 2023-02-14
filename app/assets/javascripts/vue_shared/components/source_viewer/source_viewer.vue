<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import { EVENT_ACTION, EVENT_LABEL_VIEWER } from './constants';
import Chunk from './components/chunk.vue';

export default {
  components: {
    Chunk,
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  inject: {
    highlightWorker: { default: null },
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
  },
  created() {
    this.track(EVENT_ACTION, { label: EVENT_LABEL_VIEWER, property: this.blob.language });
    addBlobLinksTracking();
  },
  userColorScheme: window.gon.user_color_scheme,
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
      v-for="(chunk, _, index) in chunks"
      :key="index"
      :chunk-index="index"
      :is-highlighted="Boolean(chunk.isHighlighted)"
      :raw-content="chunk.rawContent"
      :highlighted-content="chunk.highlightedContent"
      :total-lines="chunk.totalLines"
      :starting-from="chunk.startingFrom"
      :blame-path="blob.blamePath"
    />
  </div>
</template>
