<script>
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import { GlSprintf, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { VARIANT_DANGER } from '~/alert';
import { createContentEditor } from '../services/create_content_editor';
import { ALERT_EVENT, TIPTAP_AUTOFOCUS_OPTIONS } from '../constants';
import ContentEditorAlert from './content_editor_alert.vue';
import ContentEditorProvider from './content_editor_provider.vue';
import EditorStateObserver from './editor_state_observer.vue';
import FormattingBubbleMenu from './bubble_menus/formatting_bubble_menu.vue';
import CodeBlockBubbleMenu from './bubble_menus/code_block_bubble_menu.vue';
import LinkBubbleMenu from './bubble_menus/link_bubble_menu.vue';
import MediaBubbleMenu from './bubble_menus/media_bubble_menu.vue';
import FormattingToolbar from './formatting_toolbar.vue';
import LoadingIndicator from './loading_indicator.vue';

export default {
  components: {
    GlSprintf,
    GlLink,
    LoadingIndicator,
    ContentEditorAlert,
    ContentEditorProvider,
    TiptapEditorContent,
    FormattingToolbar,
    FormattingBubbleMenu,
    CodeBlockBubbleMenu,
    LinkBubbleMenu,
    MediaBubbleMenu,
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
    quickActionsDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    drawioEnabled: {
      type: Boolean,
      required: false,
      default: false,
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
  },
  data() {
    return {
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
      tiptapOptions: {
        autofocus,
        editable,
      },
    });
  },
  mounted() {
    this.$emit('initialized');
    this.setSerializedContent(this.markdown);
  },
  beforeDestroy() {
    this.contentEditor.dispose();
  },
  methods: {
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
      this.focused = true;
    },
    blur() {
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
  },
  i18n: {
    quickActionsText: s__(
      'ContentEditor|For %{quickActionsDocsLinkStart}quick actions%{quickActionsDocsLinkEnd}, type %{keyboardStart}/%{keyboardEnd}.',
    ),
  },
};
</script>
<template>
  <content-editor-provider :content-editor="contentEditor">
    <div>
      <editor-state-observer
        @docUpdate="notifyChange"
        @focus="focus"
        @blur="blur"
        @keydown="$emit('keydown', $event)"
      />
      <content-editor-alert />
      <div
        data-testid="content-editor"
        data-qa-selector="content_editor_container"
        class="md-area"
        :class="{ 'is-focused': focused }"
      >
        <formatting-toolbar ref="toolbar" @enableMarkdownEditor="$emit('enableMarkdownEditor')" />
        <div class="gl-relative">
          <formatting-bubble-menu />
          <code-block-bubble-menu />
          <link-bubble-menu />
          <media-bubble-menu />
          <div v-if="showPlaceholder" class="gl-absolute gl-text-gray-400 gl-px-5 gl-pt-4">
            {{ placeholder }}
          </div>
          <tiptap-editor-content
            class="md gl-px-5"
            data-testid="content_editor_editablebox"
            :editor="contentEditor.tiptapEditor"
          />
          <loading-indicator v-if="isLoading" />
          <div
            v-if="quickActionsDocsPath"
            class="gl-display-flex gl-align-items-center gl-rounded-bottom-left-base gl-rounded-bottom-right-base gl-px-4 gl-mx-2 gl-mb-2 gl-bg-gray-10 gl-text-secondary"
          >
            <div class="gl-w-full gl-line-height-32 gl-font-sm">
              <gl-sprintf :message="$options.i18n.quickActionsText">
                <template #keyboard="{ content }">
                  <kbd>{{ content }}</kbd>
                </template>
                <template #quickActionsDocsLink="{ content }">
                  <gl-link :href="quickActionsDocsPath" target="_blank" class="gl-font-sm">{{
                    content
                  }}</gl-link>
                </template>
              </gl-sprintf>
            </div>
          </div>
        </div>
      </div>
    </div>
  </content-editor-provider>
</template>
