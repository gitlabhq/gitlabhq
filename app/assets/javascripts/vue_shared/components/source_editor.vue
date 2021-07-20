<script>
import { debounce } from 'lodash';
import { CONTENT_UPDATE_DEBOUNCE, EDITOR_READY_EVENT } from '~/editor/constants';
import Editor from '~/editor/source_editor';

function initSourceEditor({ el, ...args }) {
  const editor = new Editor({
    scrollbar: {
      alwaysConsumeMouseWheel: false,
    },
  });

  return editor.createInstance({
    el,
    ...args,
  });
}

export default {
  inheritAttrs: false,
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
    extensions: {
      type: [String, Array],
      required: false,
      default: () => null,
    },
    editorOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      loading: true,
      editor: null,
    };
  },
  watch: {
    fileName(newVal) {
      this.editor.updateModelLanguage(newVal);
    },
    value(newVal) {
      if (this.editor.getValue() !== newVal) {
        this.editor.setValue(newVal);
      }
    },
  },
  mounted() {
    this.editor = initSourceEditor({
      el: this.$refs.editor,
      blobPath: this.fileName,
      blobContent: this.value,
      blobGlobalId: this.fileGlobalId,
      extensions: this.extensions,
      ...this.editorOptions,
    });

    this.editor.onDidChangeModelContent(
      debounce(this.onFileChange.bind(this), CONTENT_UPDATE_DEBOUNCE),
    );
  },
  beforeDestroy() {
    this.editor.dispose();
  },
  methods: {
    onFileChange() {
      this.$emit('input', this.editor.getValue());
    },
    getEditor() {
      return this.editor;
    },
  },
  readyEvent: EDITOR_READY_EVENT,
};
</script>
<template>
  <div
    :id="`source-editor-${fileGlobalId}`"
    ref="editor"
    data-editor-loading
    @[$options.readyEvent]="$emit($options.readyEvent)"
  >
    <pre class="editor-loading-content">{{ value }}</pre>
  </div>
</template>
