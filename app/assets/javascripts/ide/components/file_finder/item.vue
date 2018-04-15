<script>
import { escape } from 'underscore';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import FileIcon from '../../../vue_shared/components/file_icon.vue';
import ChangedFileIcon from '../changed_file_icon.vue';

const MAX_PATH_LENGTH = 60;

export default {
  components: {
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
  },
  computed: {
    pathWithEllipsis() {
      return this.file.path.length < MAX_PATH_LENGTH || !addEllipsis
        ? this.file.path
        : `...${this.file.path.substr(this.file.path.length - MAX_PATH_LENGTH)}`;
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
  },
};
</script>

<template>
  <a
    href="#"
    class="diff-changed-file"
    :class="{
      'is-focused': focused,
    }"
    @click.prevent="clickRow"
    @mouseover="mouseOverRow"
  >
    <file-icon
      :file-name="file.name"
      :size="16"
      css-classes="diff-file-changed-icon append-right-8"
    />
    <span class="diff-changed-file-content append-right-8">
      <strong
        class="diff-changed-file-name"
      >
        <span
          v-for="(char, index) in file.name.split('')"
          :key="index + char"
          :class="{
            highlighted: nameSearchTextOccurences.indexOf(index) >= 0,
          }"
          v-text="char"
        >
        </span>
      </strong>
      <span
        class="diff-changed-file-path prepend-top-5"
      >
        <span
          v-for="(char, index) in pathWithEllipsis.split('')"
          :key="index + char"
          :class="{
            highlighted: pathSearchTextOccurences.indexOf(index) >= 0,
          }"
          v-text="char"
        >
        </span>
      </span>
    </span>
    <span
      v-if="file.changed || file.tempFile"
      class="diff-changed-stats"
    >
      <changed-file-icon
        :file="file"
      />
    </span>
  </a>
</template>
