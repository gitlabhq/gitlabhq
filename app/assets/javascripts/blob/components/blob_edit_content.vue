<script>
import { initEditorLite } from '~/blob/utils';

export default {
  props: {
    value: {
      type: String,
      required: true,
    },
    fileName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      content: this.value,
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
      blobContent: this.content,
    });
  },
  methods: {
    triggerFileChange() {
      const val = this.editor.getValue();
      this.content = val;
      this.$emit('input', val);
    },
  },
};
</script>
<template>
  <div class="file-content code">
    <pre id="editor" ref="editor" data-editor-loading @focusout="triggerFileChange">{{
      content
    }}</pre>
  </div>
</template>
