<script>
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import { ContentEditor } from '../services/content_editor';
import TopToolbar from './top_toolbar.vue';

export default {
  components: {
    TiptapEditorContent,
    TopToolbar,
  },
  props: {
    contentEditor: {
      type: ContentEditor,
      required: true,
    },
  },
};
</script>
<template>
  <div class="md md-area" :class="{ 'is-focused': contentEditor.tiptapEditor.isFocused }">
    <top-toolbar class="gl-mb-4" :content-editor="contentEditor" />
    <tiptap-editor-content :editor="contentEditor.tiptapEditor" />
  </div>
</template>
