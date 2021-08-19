<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import { LOADING_CONTENT_EVENT, LOADING_SUCCESS_EVENT, LOADING_ERROR_EVENT } from '../constants';
import { createContentEditor } from '../services/create_content_editor';
import ContentEditorError from './content_editor_error.vue';
import ContentEditorProvider from './content_editor_provider.vue';
import EditorStateObserver from './editor_state_observer.vue';
import FormattingBubbleMenu from './formatting_bubble_menu.vue';
import TopToolbar from './top_toolbar.vue';

export default {
  components: {
    GlLoadingIcon,
    ContentEditorError,
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
      isLoadingContent: false,
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

    this.contentEditor.on(LOADING_CONTENT_EVENT, this.displayLoadingIndicator);
    this.contentEditor.on(LOADING_SUCCESS_EVENT, this.hideLoadingIndicator);
    this.contentEditor.on(LOADING_ERROR_EVENT, this.hideLoadingIndicator);
    this.$emit('initialized', this.contentEditor);
  },
  beforeDestroy() {
    this.contentEditor.dispose();
    this.contentEditor.off(LOADING_CONTENT_EVENT, this.displayLoadingIndicator);
    this.contentEditor.off(LOADING_SUCCESS_EVENT, this.hideLoadingIndicator);
    this.contentEditor.off(LOADING_ERROR_EVENT, this.hideLoadingIndicator);
  },
  methods: {
    displayLoadingIndicator() {
      this.isLoadingContent = true;
    },
    hideLoadingIndicator() {
      this.isLoadingContent = false;
    },
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
      <content-editor-error />
      <div
        data-testid="content-editor"
        data-qa-selector="content_editor_container"
        class="md-area"
        :class="{ 'is-focused': focused }"
      >
        <top-toolbar ref="toolbar" class="gl-mb-4" />
        <formatting-bubble-menu />
        <div v-if="isLoadingContent" class="gl-w-full gl-display-flex gl-justify-content-center">
          <gl-loading-icon size="sm" />
        </div>
        <tiptap-editor-content v-else class="md" :editor="contentEditor.tiptapEditor" />
      </div>
    </div>
  </content-editor-provider>
</template>
