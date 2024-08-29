<script>
import BlobChunks from '~/search/results/components/blob_chunks.vue';
import { DEFAULT_SHOW_CHUNKS } from '~/search/results/constants';
import eventHub from '../event_hub';

export default {
  name: 'ZoektBlobResultsChunks',
  components: {
    BlobChunks,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showMore: false,
    };
  },
  computed: {
    projectPathAndFilePath() {
      return `${this.file.projectPath}:${this.file.path}`;
    },
  },
  mounted() {
    eventHub.$on('showMore', this.toggleShowMore);
  },
  destroyed() {
    eventHub.$off('showMore', this.toggleShowMore);
  },
  methods: {
    toggleShowMore({ id, state }) {
      if (id === this.projectPathAndFilePath) {
        this.showMore = state;
      }
    },
    chunksToShow(file) {
      if (this.showMore) {
        return file.chunks;
      }
      return file.chunks.slice(0, DEFAULT_SHOW_CHUNKS);
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(chunk, index) in chunksToShow(file)"
      :key="`chunk${index}`"
      class="chunks-block gl-border-b gl-border-subtle last:gl-border-0"
    >
      <blob-chunks :chunk="chunk" :blame-link="file.blameUrl" :file-url="file.fileUrl" />
    </div>
  </div>
</template>
