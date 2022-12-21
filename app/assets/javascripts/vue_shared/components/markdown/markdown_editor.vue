<script>
import axios from '~/lib/utils/axios_utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { EDITING_MODE_MARKDOWN_FIELD, EDITING_MODE_CONTENT_EDITOR } from '../../constants';
import MarkdownField from './field.vue';

export default {
  components: {
    LocalStorageSync,
    MarkdownField,
    ContentEditor: () =>
      import(
        /* webpackChunkName: 'content_editor' */ '~/content_editor/components/content_editor.vue'
      ),
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    renderMarkdownPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    quickActionsDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    uploadsPath: {
      type: String,
      required: false,
      default: () => window.uploads_path,
    },
    enableContentEditor: {
      type: Boolean,
      required: false,
      default: true,
    },
    formFieldId: {
      type: String,
      required: true,
    },
    formFieldName: {
      type: String,
      required: true,
    },
    enablePreview: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
    formFieldPlaceholder: {
      type: String,
      required: false,
      default: '',
    },
    formFieldAriaLabel: {
      type: String,
      required: false,
      default: '',
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
    supportsQuickActions: {
      type: Boolean,
      required: false,
      default: false,
    },
    useBottomToolbar: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      editingMode: EDITING_MODE_MARKDOWN_FIELD,
      autofocused: false,
    };
  },
  computed: {
    isContentEditorActive() {
      return this.enableContentEditor && this.editingMode === EDITING_MODE_CONTENT_EDITOR;
    },
    contentEditorAutofocused() {
      // Match textarea focus behavior
      return this.autofocus && !this.autofocused ? 'end' : false;
    },
  },
  mounted() {
    this.autofocusTextarea();
  },
  methods: {
    updateMarkdownFromContentEditor({ markdown }) {
      this.$emit('input', markdown);
    },
    updateMarkdownFromMarkdownField({ target }) {
      this.$emit('input', target.value);
    },
    renderMarkdown(markdown) {
      return axios.post(this.renderMarkdownPath, { text: markdown }).then(({ data }) => data.body);
    },
    onEditingModeChange(editingMode) {
      this.editingMode = editingMode;
      this.notifyEditingModeChange(editingMode);
    },
    onEditingModeRestored(editingMode) {
      this.editingMode = editingMode;
      this.$emit(editingMode);
      this.notifyEditingModeChange(editingMode);
    },
    notifyEditingModeChange(editingMode) {
      this.$emit(editingMode);
    },
    autofocusTextarea() {
      if (this.autofocus && this.editingMode === EDITING_MODE_MARKDOWN_FIELD) {
        this.$refs.textarea.focus();
        this.setEditorAsAutofocused();
      }
    },
    setEditorAsAutofocused() {
      this.autofocused = true;
    },
  },
};
</script>
<template>
  <div>
    <local-storage-sync
      v-model="editingMode"
      storage-key="gl-wiki-content-editor-enabled"
      @input="onEditingModeRestored"
    />
    <markdown-field
      v-if="!isContentEditorActive"
      :markdown-preview-path="renderMarkdownPath"
      can-attach-file
      :enable-autocomplete="enableAutocomplete"
      :textarea-value="value"
      :markdown-docs-path="markdownDocsPath"
      :quick-actions-docs-path="quickActionsDocsPath"
      :uploads-path="uploadsPath"
      :enable-preview="enablePreview"
      show-content-editor-switcher
      class="bordered-box"
      @enableContentEditor="onEditingModeChange('contentEditor')"
    >
      <template #textarea>
        <textarea
          :id="formFieldId"
          ref="textarea"
          :value="value"
          :name="formFieldName"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          dir="auto"
          :data-supports-quick-actions="supportsQuickActions"
          data-qa-selector="markdown_editor_form_field"
          :aria-label="formFieldAriaLabel"
          :placeholder="formFieldPlaceholder"
          @input="updateMarkdownFromMarkdownField"
          @keydown="$emit('keydown', $event)"
        >
        </textarea>
      </template>
    </markdown-field>
    <div v-else>
      <content-editor
        :render-markdown="renderMarkdown"
        :uploads-path="uploadsPath"
        :markdown="value"
        :autofocus="contentEditorAutofocused"
        :use-bottom-toolbar="useBottomToolbar"
        @initialized="setEditorAsAutofocused"
        @change="updateMarkdownFromContentEditor"
        @keydown="$emit('keydown', $event)"
        @enableMarkdownEditor="onEditingModeChange('markdownField')"
      />
      <input
        :id="formFieldId"
        :value="value"
        :name="formFieldName"
        data-qa-selector="markdown_editor_form_field"
        type="hidden"
      />
    </div>
  </div>
</template>
