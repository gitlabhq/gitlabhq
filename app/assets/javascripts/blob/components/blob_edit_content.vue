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
    // This is used to help uniquely create a monaco model
    // even if two blob's share a file path.
    fileGlobalId: {
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
      blobGlobalId: this.fileGlobalId,
    });

    this.editor.onChangeContent(debounce(this.onFileChange.bind(this), 250));

    window.requestAnimationFrame(() => {
      if (!performance.getEntriesByName(SNIPPET_MARK_BLOBS_CONTENT).length) {
        performance.mark(SNIPPET_MARK_BLOBS_CONTENT);
        performance.measure(SNIPPET_MEASURE_BLOBS_CONTENT);
        performance.measure(SNIPPET_MEASURE_BLOBS_CONTENT_WITHIN_APP, SNIPPET_MARK_EDIT_APP_START);
      }
    });
  },
  beforeDestroy() {
    this.editor.dispose();
  },
  methods: {
    onFileChange() {
      this.$emit('input', this.editor.getValue());
    },
  },
};
</script>
<template>
  <div class="file-content code">
    <div id="editor" ref="editor" data-editor-loading>
      <pre class="editor-loading-content">{{ value }}</pre>
    </div>
  </div>
</template>
