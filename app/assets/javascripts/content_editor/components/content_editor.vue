<script>
import { EditorContent, Editor } from 'tiptap';
import TopToolbar from './top_toolbar.vue';

export default {
  components: {
    EditorContent,
    TopToolbar,
  },
  props: {
    editor: {
      type: Object,
      required: true,
      validator: (editor) => editor instanceof Editor,
    },
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-p-3 gl-border-solid gl-border-1 gl-border-gray-200 gl-rounded-base"
  >
    <top-toolbar class="gl-mb-3" :editor="editor" />
    <editor-content class="md" :editor="editor" />
  </div>
</template>
