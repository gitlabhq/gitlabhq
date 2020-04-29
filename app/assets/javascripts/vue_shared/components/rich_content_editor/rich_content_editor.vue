<script>
import 'codemirror/lib/codemirror.css';
import '@toast-ui/editor/dist/toastui-editor.css';

import { EDITOR_OPTIONS, EDITOR_TYPES } from './constants';

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
  },
  methods: {
    onContentChanged() {
      this.$emit('input', this.getMarkdown());
    },
    getMarkdown() {
      return this.$refs.editor.invoke('getMarkdown');
    },
  },
  editorOptions: EDITOR_OPTIONS,
  initialEditType: EDITOR_TYPES.wysiwyg,
};
</script>
<template>
  <toast-editor
    ref="editor"
    :initial-edit-type="$options.initialEditType"
    :initial-value="value"
    :options="$options.editorOptions"
    @change="onContentChanged"
  />
</template>
