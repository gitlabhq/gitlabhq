<script>
import { EditorContent } from 'tiptap';
import createEditor from '../services/create_editor';

export default {
  components: {
    EditorContent,
  },
  data() {
    return {
      editor: createEditor(),
    };
  },
};
</script>
<template>
  <editor-content :editor="editor" />
</template>
