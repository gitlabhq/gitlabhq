<script>
import { GlAlert } from '@gitlab/ui';
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import { ContentEditor } from '../services/content_editor';
import TopToolbar from './top_toolbar.vue';

export default {
  components: {
    GlAlert,
    TiptapEditorContent,
    TopToolbar,
  },
  props: {
    contentEditor: {
      type: ContentEditor,
      required: true,
    },
  },
  data() {
    return {
      error: '',
    };
  },
  mounted() {
    this.contentEditor.tiptapEditor.on('error', (error) => {
      this.error = error;
    });
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error" class="gl-mb-6" variant="danger" @dismiss="error = ''">
      {{ error }}
    </gl-alert>
    <div
      data-testid="content-editor"
      class="md-area"
      :class="{ 'is-focused': contentEditor.tiptapEditor.isFocused }"
    >
      <top-toolbar ref="toolbar" class="gl-mb-4" :content-editor="contentEditor" />
      <tiptap-editor-content class="md" :editor="contentEditor.tiptapEditor" />
    </div>
  </div>
</template>
