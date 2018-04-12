<script>
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import FileIcon from '../../../vue_shared/components/file_icon.vue';

const MAX_PATH_LENGTH = 60;

export default {
  components: {
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
  },
  methods: {
    clickRow() {
      this.$emit('click', this.file);
    },
    highlightText(text, addEllipsis) {
      const maxText =
        text.length < MAX_PATH_LENGTH || !addEllipsis
          ? text
          : `...${text.substr(text.length - MAX_PATH_LENGTH)}`;
      const occurrences = fuzzaldrinPlus.match(maxText, this.searchText);

      return maxText
        .split('')
        .map(
          (char, i) =>
            `<span class="${occurrences.indexOf(i) >= 0 ? 'highlighted' : ''}">${char}</span>`,
        )
        .join('');
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
  >
    <file-icon
      :file-name="file.name"
      :size="16"
      css-classes="diff-file-changed-icon append-right-8"
    />
    <span class="diff-changed-file-content append-right-8">
      <strong
        class="diff-changed-file-name"
        v-html="highlightText(file.name, false)"
      >
      </strong>
      <span
        class="diff-changed-file-path prepend-top-5"
        v-html="highlightText(file.path, true)"
      >
      </span>
    </span>
  </a>
</template>
