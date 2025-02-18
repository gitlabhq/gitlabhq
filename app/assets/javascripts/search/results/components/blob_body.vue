<script>
import BlobChunks from '~/search/results/components/blob_chunks.vue';
import {
  DEFAULT_SHOW_CHUNKS,
  CODE_THEME_DEFAULT,
  CODE_THEME_NONE,
  CODE_THEME_DARK,
  CODE_THEME_MONOKAI,
  CODE_THEME_SOLARIZED_DARK,
  CODE_THEME_SOLARIZED_LIGHT,
  BORDER_DARK,
  BORDER_LIGHT,
} from '../constants';
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
    position: {
      type: Number,
      required: true,
    },
    systemColorScheme: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showMore: false,
      numberOfChunksToShow: DEFAULT_SHOW_CHUNKS,
    };
  },
  computed: {
    projectPathAndFilePath() {
      return `${this.file.projectPath}:${this.file.path}`;
    },
    codeTheme() {
      return gon?.user_color_scheme || CODE_THEME_DEFAULT;
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
        this.numberOfChunksToShow = file.chunks.length;
        return file.chunks;
      }

      this.numberOfChunksToShow = DEFAULT_SHOW_CHUNKS;
      return file.chunks.slice(0, DEFAULT_SHOW_CHUNKS);
    },
    isLast(index) {
      return index + 1 === this.numberOfChunksToShow;
    },
    dividerTheme(index) {
      if (this.isLast(index)) return '';

      switch (this.codeTheme) {
        case CODE_THEME_SOLARIZED_LIGHT:
        case CODE_THEME_DEFAULT:
        case CODE_THEME_NONE:
          return BORDER_LIGHT;
        case CODE_THEME_MONOKAI:
        case CODE_THEME_SOLARIZED_DARK:
        case CODE_THEME_DARK:
        default:
          return BORDER_DARK;
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(chunk, index) in chunksToShow(file)"
      :key="`chunk${index}`"
      class="chunks-block gl-rounded-none"
      :class="[codeTheme, dividerTheme(index)]"
    >
      <blob-chunks
        :chunk="chunk"
        :language="file.language"
        :blame-link="file.blameUrl"
        :file-url="file.fileUrl"
        :position="position"
      />
    </div>
  </div>
</template>
