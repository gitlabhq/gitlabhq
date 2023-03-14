<script>
import Autosize from 'autosize';
import axios from '~/lib/utils/axios_utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { updateDraft, clearDraft, getDraft } from '~/lib/utils/autosave';
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
    formFieldProps: {
      type: Object,
      required: true,
      validator: (prop) => prop.id && prop.name,
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
    autosaveKey: {
      type: String,
      required: false,
      default: null,
    },
    quickActionsDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      markdown: this.value || (this.autosaveKey ? getDraft(this.autosaveKey) : '') || '',
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
  watch: {
    value(val) {
      this.markdown = val;

      this.saveDraft();
      this.autosizeTextarea();
    },
  },
  mounted() {
    this.autofocusTextarea();

    this.saveDraft();
  },
  methods: {
    updateMarkdownFromContentEditor({ markdown }) {
      this.markdown = markdown;
      this.$emit('input', markdown);

      this.saveDraft();
    },
    updateMarkdownFromMarkdownField({ target }) {
      this.markdown = target.value;
      this.$emit('input', target.value);

      this.saveDraft();
      this.autosizeTextarea();
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
    saveDraft() {
      if (!this.autosaveKey) return;
      if (this.markdown) updateDraft(this.autosaveKey, this.markdown);
      else clearDraft(this.autosaveKey);
    },
    autosizeTextarea() {
      if (this.editingMode === EDITING_MODE_MARKDOWN_FIELD) {
        this.$nextTick(() => {
          Autosize.update(this.$refs.textarea);
        });
      }
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
      v-bind="$attrs"
      data-testid="markdown-field"
      :markdown-preview-path="renderMarkdownPath"
      can-attach-file
      :textarea-value="markdown"
      :uploads-path="uploadsPath"
      :quick-actions-docs-path="quickActionsDocsPath"
      show-content-editor-switcher
      class="bordered-box"
      @enableContentEditor="onEditingModeChange('contentEditor')"
    >
      <template #textarea>
        <textarea
          v-bind="formFieldProps"
          ref="textarea"
          :value="markdown"
          class="note-textarea js-gfm-input markdown-area"
          dir="auto"
          :data-supports-quick-actions="supportsQuickActions"
          data-qa-selector="markdown_editor_form_field"
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
        :markdown="markdown"
        :quick-actions-docs-path="quickActionsDocsPath"
        :autofocus="contentEditorAutofocused"
        @initialized="setEditorAsAutofocused"
        @change="updateMarkdownFromContentEditor"
        @keydown="$emit('keydown', $event)"
        @enableMarkdownEditor="onEditingModeChange('markdownField')"
      />
      <input
        v-bind="formFieldProps"
        :value="markdown"
        data-qa-selector="markdown_editor_form_field"
        type="hidden"
      />
    </div>
  </div>
</template>
