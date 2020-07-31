<script>
import { initEditorLite } from '~/blob/utils';
import { debounce } from 'lodash';
import {
  SNIPPET_MARK_BLOBS_CONTENT,
  SNIPPET_MARK_EDIT_APP_START,
  SNIPPET_MEASURE_BLOBS_CONTENT,
  SNIPPET_MEASURE_BLOBS_CONTENT_WITHIN_APP,
} from '~/performance_constants';

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
    window.requestAnimationFrame(() => {
      if (!performance.getEntriesByName(SNIPPET_MARK_BLOBS_CONTENT).length) {
        performance.mark(SNIPPET_MARK_BLOBS_CONTENT);
        performance.measure(SNIPPET_MEASURE_BLOBS_CONTENT);
        performance.measure(SNIPPET_MEASURE_BLOBS_CONTENT_WITHIN_APP, SNIPPET_MARK_EDIT_APP_START);
      }
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
    <div id="editor" ref="editor" data-editor-loading @keyup="triggerFileChange">
      <pre class="editor-loading-content">{{ value }}</pre>
    </div>
  </div>
</template>
