<script>
import { debounce, isEmpty } from 'lodash';
import { CONTENT_UPDATE_DEBOUNCE, EDITOR_READY_EVENT } from '~/editor/constants';
import Editor from '~/editor/source_editor';
import { markRaw } from '~/lib/utils/vue3compat/mark_raw';

function initSourceEditor({ el, ...args }) {
  const editor = new Editor({
    scrollbar: {
      alwaysConsumeMouseWheel: false,
    },
  });

  return markRaw(
    editor.createInstance({
      el,
      ...args,
    }),
  );
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
      type: [Object, Array],
      required: false,
      default: () => ({}),
    },
    editorOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    debounceValue: {
      type: Number,
      required: false,
      default: CONTENT_UPDATE_DEBOUNCE,
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
      ...this.editorOptions,
    });

    this.editor.onDidChangeModelContent(debounce(this.onFileChange.bind(this), this.debounceValue));
    if (!isEmpty(this.extensions)) {
      this.editor.use(this.extensions);
    }
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
    data-testid="source-editor-container"
    @[$options.readyEvent]="$emit($options.readyEvent, $event)"
  >
    <pre class="editor-loading-content">{{ value }}</pre>
  </div>
</template>
