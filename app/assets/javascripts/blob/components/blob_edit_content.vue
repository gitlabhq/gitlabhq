<script>
import { initEditorLite } from '~/blob/utils';

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
    triggerFileChange() {
      this.$emit('input', this.editor.getValue());
    },
  },
};
</script>
<template>
  <div class="file-content code">
    <pre id="editor" ref="editor" data-editor-loading @focusout="triggerFileChange">{{
      value
    }}</pre>
  </div>
</template>
