<script>
import { debounce } from 'lodash';
import { initSourceEditor } from '~/blob/utils';
import { SNIPPET_MEASURE_BLOBS_CONTENT } from '~/performance/constants';

import eventHub from './eventhub';

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
    this.editor = initSourceEditor({
      el: this.$refs.editor,
      blobPath: this.fileName,
      blobContent: this.value,
      blobGlobalId: this.fileGlobalId,
    });

    this.editor.onDidChangeModelContent(debounce(this.onFileChange.bind(this), 250));

    eventHub.$emit(SNIPPET_MEASURE_BLOBS_CONTENT);
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
