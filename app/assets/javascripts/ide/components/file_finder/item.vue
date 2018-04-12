<script>
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import FileIcon from '../../../vue_shared/components/file_icon.vue';

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
    highlightText(text) {
      const occurrences = fuzzaldrinPlus.match(text, this.searchText);

      return text
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
        v-html="highlightText(this.file.name)"
      >
      </strong>
      <span
        class="diff-changed-file-path prepend-top-5"
        v-html="highlightText(this.file.path)"
      >
      </span>
    </span>
  </a>
</template>

<style>
.highlighted {
  color: #1b69b6;
  font-weight: 600;
}
</style>
