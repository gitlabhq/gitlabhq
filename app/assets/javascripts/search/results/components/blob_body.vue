<script>
import BlobChunks from '~/search/results/components/blob_chunks.vue';
import { GL_DARK } from '~/constants';
import {
  DEFAULT_SHOW_CHUNKS,
  CODE_THEME_DEFAULT,
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
    };
  },
  computed: {
    projectPathAndFilePath() {
      return `${this.file.projectPath}:${this.file.path}`;
    },
    codeTheme() {
      return gon?.user_color_scheme || CODE_THEME_DEFAULT;
    },
    dividerTheme() {
      switch (this.codeTheme) {
        case CODE_THEME_SOLARIZED_LIGHT:
        case CODE_THEME_DEFAULT:
          return this.systemColorScheme === GL_DARK ? BORDER_LIGHT : BORDER_DARK;
        case CODE_THEME_MONOKAI:
        case CODE_THEME_SOLARIZED_DARK:
        case CODE_THEME_DARK:
        default:
          return this.systemColorScheme !== GL_DARK ? BORDER_DARK : BORDER_LIGHT;
      }
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
      class="chunks-block !gl-border-b gl-rounded-none last:gl-border-0"
      :class="[codeTheme, dividerTheme]"
    >
      <blob-chunks
        :chunk="chunk"
        :blame-link="file.blameUrl"
        :file-url="file.fileUrl"
        :position="position"
      />
    </div>
  </div>
</template>
