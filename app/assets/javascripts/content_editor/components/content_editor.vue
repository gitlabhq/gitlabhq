<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import { isEqual } from 'lodash';
import { __ } from '~/locale';
import { VARIANT_DANGER } from '~/alert';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';
import { CONTENT_EDITOR_READY_EVENT, CONTENT_EDITOR_PASTE } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import { createContentEditor } from '../services/create_content_editor';
import { ALERT_EVENT, TIPTAP_AUTOFOCUS_OPTIONS } from '../constants';
import ContentEditorAlert from './content_editor_alert.vue';
import ContentEditorProvider from './content_editor_provider.vue';
import EditorStateObserver from './editor_state_observer.vue';
import CodeBlockBubbleMenu from './bubble_menus/code_block_bubble_menu.vue';
import LinkBubbleMenu from './bubble_menus/link_bubble_menu.vue';
import MediaBubbleMenu from './bubble_menus/media_bubble_menu.vue';
import ReferenceBubbleMenu from './bubble_menus/reference_bubble_menu.vue';
import FormattingToolbar from './formatting_toolbar.vue';
import LoadingIndicator from './loading_indicator.vue';

export default {
  components: {
    GlButton,
    LoadingIndicator,
    ContentEditorAlert,
    ContentEditorProvider,
    TiptapEditorContent,
    FormattingToolbar,
    CodeBlockBubbleMenu,
    LinkBubbleMenu,
    MediaBubbleMenu,
    EditorStateObserver,
    ReferenceBubbleMenu,
    EditorModeSwitcher,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    renderMarkdown: {
      type: Function,
      required: true,
    },
    markdownDocsPath: {
      type: String,
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
    markdown: {
      type: String,
      required: false,
      default: '',
    },
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    autofocus: {
      type: [String, Boolean],
      required: false,
      default: false,
      validator: (autofocus) => TIPTAP_AUTOFOCUS_OPTIONS.includes(autofocus),
    },
    supportsQuickActions: {
      type: Boolean,
      required: false,
      default: false,
    },
    drawioEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    codeSuggestionsConfig: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    editable: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    disableAttachments: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      contentEditor: null,
      focused: false,
      isLoading: false,
      latestMarkdown: null,
    };
  },
  computed: {
    showPlaceholder() {
      return this.placeholder && !this.markdown && !this.focused;
    },
  },
  watch: {
    autocompleteDataSources(newDataSources, oldDataSources) {
      if (!isEqual(newDataSources, oldDataSources)) {
        this.contentEditor.updateAutocompleteDataSources(newDataSources);
      }
    },
    markdown(markdown) {
      if (markdown !== this.latestMarkdown) {
        this.setSerializedContent(markdown);
      }
    },
    editable(value) {
      this.contentEditor.setEditable(value);
    },
  },
  created() {
    const {
      renderMarkdown,
      uploadsPath,
      extensions,
      serializerConfig,
      autofocus,
      drawioEnabled,
      editable,
      enableAutocomplete,
      autocompleteDataSources,
      codeSuggestionsConfig,
    } = this;

    // This is a non-reactive attribute intentionally since this is a complex object.
    this.contentEditor = createContentEditor({
      renderMarkdown,
      uploadsPath,
      extensions,
      serializerConfig,
      drawioEnabled,
      enableAutocomplete,
      autocompleteDataSources,
      codeSuggestionsConfig,
      sidebarMediator: SidebarMediator.singleton,
      tiptapOptions: {
        autofocus,
        editable,
      },
    });
  },
  async mounted() {
    this.$emit('initialized');
    await this.setSerializedContent(this.markdown);
    markdownEditorEventHub.$emit(CONTENT_EDITOR_READY_EVENT);
    markdownEditorEventHub.$on(CONTENT_EDITOR_PASTE, this.pasteContent);
  },
  beforeDestroy() {
    markdownEditorEventHub.$off(CONTENT_EDITOR_PASTE, this.pasteContent);
    this.contentEditor.dispose();
  },
  methods: {
    pasteContent(content) {
      this.contentEditor.tiptapEditor.chain().focus().pasteContent(content).run();
    },
    async setSerializedContent(markdown) {
      this.notifyLoading();

      try {
        await this.contentEditor.setSerializedContent(markdown);
        this.notifyLoadingSuccess();
        this.latestMarkdown = markdown;
      } catch {
        this.contentEditor.setEditable(false);
        this.contentEditor.eventHub.$emit(ALERT_EVENT, {
          message: __(
            'An error occurred while trying to render the content editor. Please try again.',
          ),
          variant: VARIANT_DANGER,
          actionLabel: __('Retry'),
          action: () => {
            this.contentEditor.setEditable(true);
            this.setSerializedContent(markdown);
          },
        });
        this.notifyLoadingError();
      }
    },
    focus() {
      this.contentEditor.tiptapEditor.commands.focus();
    },
    onFocus() {
      this.focused = true;
    },
    onBlur() {
      this.focused = false;
    },
    notifyLoading() {
      this.isLoading = true;
      this.$emit('loading');
    },
    notifyLoadingSuccess() {
      this.isLoading = false;
      this.$emit('loadingSuccess');
    },
    notifyLoadingError(error) {
      this.isLoading = false;
      this.$emit('loadingError', error);
    },
    notifyChange() {
      this.latestMarkdown = this.contentEditor.getSerializedContent();

      this.$emit('change', {
        empty: this.contentEditor.empty,
        changed: this.contentEditor.changed,
        markdown: this.latestMarkdown,
      });
    },
    handleEditorModeChanged() {
      this.$emit('enableMarkdownEditor');
    },
  },
};
</script>
<template>
  <content-editor-provider :content-editor="contentEditor">
    <div class="md-area gl-overflow-hidden">
      <editor-state-observer
        @docUpdate="notifyChange"
        @focus="onFocus"
        @blur="onBlur"
        @keydown="$emit('keydown', $event)"
      />
      <content-editor-alert />
      <div data-testid="content-editor" :class="{ 'is-focused': focused }">
        <formatting-toolbar
          ref="toolbar"
          :supports-quick-actions="supportsQuickActions"
          :hide-attachment-button="disableAttachments"
          @enableMarkdownEditor="$emit('enableMarkdownEditor')"
        />
        <div v-if="showPlaceholder" class="gl-absolute gl-text-gray-400 gl-px-5 gl-pt-4">
          {{ placeholder }}
        </div>
        <tiptap-editor-content
          class="md"
          data-testid="content_editor_editablebox"
          :editor="contentEditor.tiptapEditor"
        />
        <loading-indicator v-if="isLoading" />

        <code-block-bubble-menu />
        <link-bubble-menu />
        <media-bubble-menu />
        <reference-bubble-menu />
      </div>
      <div
        class="gl-display-flex gl-display-flex gl-flex-direction-row gl-justify-content-space-between gl-align-items-center gl-rounded-bottom-left-base gl-rounded-bottom-right-base gl-px-2 gl-border-t gl-border-gray-100 gl-text-secondary"
      >
        <editor-mode-switcher size="small" value="richText" @switch="handleEditorModeChanged" />
        <gl-button
          v-gl-tooltip
          icon="markdown-mark"
          :href="markdownDocsPath"
          target="_blank"
          category="tertiary"
          size="small"
          :title="__('Markdown is supported')"
          :aria-label="__('Markdown is supported')"
          class="gl-px-3!"
        />
      </div>
    </div>
  </content-editor-provider>
</template>
