<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import ChangedFileIcon from '../changed_file_icon.vue';
import FileIcon from '../file_icon.vue';

const MAX_PATH_LENGTH = 60;

export default {
  components: {
    GlIcon,
    ChangedFileIcon,
    FileIcon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    focused: {
      type: Boolean,
      required: true,
    },
    searchText: {
      type: String,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
    showDiffStats: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    pathWithEllipsis() {
      const { path } = this.file;

      return path.length < MAX_PATH_LENGTH
        ? path
        : `...${path.substr(path.length - MAX_PATH_LENGTH)}`;
    },
    nameSearchTextOccurences() {
      return fuzzaldrinPlus.match(this.file.name, this.searchText);
    },
    pathSearchTextOccurences() {
      return fuzzaldrinPlus.match(this.pathWithEllipsis, this.searchText);
    },
  },
  methods: {
    clickRow() {
      this.$emit('click', this.file);
    },
    mouseOverRow() {
      this.$emit('mouseover', this.index);
    },
    mouseMove() {
      this.$emit('mousemove', this.index);
    },
  },
};
</script>

<template>
  <button
    :class="{
      'is-focused': focused,
    }"
    type="button"
    class="diff-changed-file"
    @click.prevent="clickRow"
    @mouseover="mouseOverRow"
    @mousemove="mouseMove"
  >
    <file-icon :file-name="file.name" :size="16" css-classes="diff-file-changed-icon gl-mr-3" />
    <span class="diff-changed-file-content gl-mr-3">
      <strong class="diff-changed-file-name">
        <span
          v-for="(char, charIndex) in file.name.split('')"
          :key="charIndex + char"
          :class="{
            highlighted: nameSearchTextOccurences.indexOf(charIndex) >= 0,
          }"
          v-text="char"
        >
        </span>
      </strong>
      <span class="diff-changed-file-path gl-mt-2">
        <span
          v-for="(char, charIndex) in pathWithEllipsis.split('')"
          :key="charIndex + char"
          :class="{
            highlighted: pathSearchTextOccurences.indexOf(charIndex) >= 0,
          }"
          v-text="char"
        >
        </span>
      </span>
    </span>
    <span v-if="file.changed || file.tempFile" v-once class="diff-changed-stats">
      <span v-if="showDiffStats">
        <span class="gl-font-bold gl-text-success">
          <gl-icon name="file-addition" class="align-text-top" /> {{ file.addedLines }}
        </span>
        <span class="ml-1 gl-font-bold gl-text-danger">
          <gl-icon name="file-deletion" class="align-text-top" /> {{ file.removedLines }}
        </span>
      </span>
      <changed-file-icon v-else :file="file" />
    </span>
  </button>
</template>

<style scoped>
.highlighted {
  color: #1f78d1;
  font-weight: 600;
}
</style>
