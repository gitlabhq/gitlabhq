<script>
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import { createContentEditor } from '../services/create_content_editor';
import ContentEditorAlert from './content_editor_alert.vue';
import ContentEditorProvider from './content_editor_provider.vue';
import EditorStateObserver from './editor_state_observer.vue';
import FormattingBubbleMenu from './formatting_bubble_menu.vue';
import TopToolbar from './top_toolbar.vue';
import LoadingIndicator from './loading_indicator.vue';

export default {
  components: {
    LoadingIndicator,
    ContentEditorAlert,
    ContentEditorProvider,
    TiptapEditorContent,
    TopToolbar,
    FormattingBubbleMenu,
    EditorStateObserver,
  },
  props: {
    renderMarkdown: {
      type: Function,
      required: true,
    },
    uploadsPath: {
      type: String,
      required: true,
    },
    extensions: {
      type: Array,
      required: false,
      default: () => [],
    },
    serializerConfig: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      focused: false,
    };
  },
  created() {
    const { renderMarkdown, uploadsPath, extensions, serializerConfig } = this;

    // This is a non-reactive attribute intentionally since this is a complex object.
    this.contentEditor = createContentEditor({
      renderMarkdown,
      uploadsPath,
      extensions,
      serializerConfig,
    });
  },
  mounted() {
    this.$emit('initialized', this.contentEditor);
  },
  beforeDestroy() {
    this.contentEditor.dispose();
  },
  methods: {
    focus() {
      this.focused = true;
    },
    blur() {
      this.focused = false;
    },
    notifyChange() {
      this.$emit('change', {
        empty: this.contentEditor.empty,
      });
    },
  },
};
</script>
<template>
  <content-editor-provider :content-editor="contentEditor">
    <div>
      <editor-state-observer @docUpdate="notifyChange" @focus="focus" @blur="blur" />
      <content-editor-alert />
      <div
        data-testid="content-editor"
        data-qa-selector="content_editor_container"
        class="md-area"
        :class="{ 'is-focused': focused }"
      >
        <top-toolbar ref="toolbar" class="gl-mb-4" />
        <div class="gl-relative">
          <formatting-bubble-menu />
          <tiptap-editor-content class="md" :editor="contentEditor.tiptapEditor" />
          <loading-indicator />
        </div>
      </div>
    </div>
  </content-editor-provider>
</template>
