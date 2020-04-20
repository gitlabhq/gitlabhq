<script>
import { initEditorLite } from '~/blob/utils';
import { debounce } from 'lodash';

export default {
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    fileName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      editor: null,
    };
  },
  watch: {
    fileName(newVal) {
      this.editor.updateModelLanguage(newVal);
    },
  },
  mounted() {
    this.editor = initEditorLite({
      el: this.$refs.editor,
      blobPath: this.fileName,
      blobContent: this.value,
    });
  },
  methods: {
    triggerFileChange: debounce(function debouncedFileChange() {
      this.$emit('input', this.editor.getValue());
    }, 250),
  },
};
</script>
<template>
  <div class="file-content code">
    <pre id="editor" ref="editor" data-editor-loading @keyup="triggerFileChange">{{ value }}</pre>
  </div>
</template>
