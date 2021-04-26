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
  <div class="md md-area" :class="{ 'is-focused': editor.focused }">
    <top-toolbar class="gl-mb-4" :editor="editor" />
    <editor-content :editor="editor" />
  </div>
</template>
