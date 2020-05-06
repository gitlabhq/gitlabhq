<script>
import 'codemirror/lib/codemirror.css';
import '@toast-ui/editor/dist/toastui-editor.css';

import { EDITOR_OPTIONS, EDITOR_TYPES, EDITOR_HEIGHT } from './constants';

export default {
  components: {
    ToastEditor: () =>
      import(/* webpackChunkName: 'toast_editor' */ '@toast-ui/vue-editor').then(
        toast => toast.Editor,
      ),
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    options: {
      type: Object,
      required: false,
      default: () => EDITOR_OPTIONS,
    },
    initialEditType: {
      type: String,
      required: false,
      default: EDITOR_TYPES.wysiwyg,
    },
    height: {
      type: String,
      required: false,
      default: EDITOR_HEIGHT,
    },
  },
  computed: {
    editorOptions() {
      return { ...EDITOR_OPTIONS, ...this.options };
    },
  },
  methods: {
    onContentChanged() {
      this.$emit('input', this.getMarkdown());
    },
    getMarkdown() {
      return this.$refs.editor.invoke('getMarkdown');
    },
  },
};
</script>
<template>
  <toast-editor
    ref="editor"
    :initial-value="value"
    :options="editorOptions"
    :initial-edit-type="initialEditType"
    :height="height"
    @change="onContentChanged"
  />
</template>
