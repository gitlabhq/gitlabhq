<script>
import Autosize from 'autosize';
import axios from '~/lib/utils/axios_utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { updateDraft, clearDraft, getDraft } from '~/lib/utils/autosave';
import { setUrlParams, joinPaths } from '~/lib/utils/url_utility';
import {
  EDITING_MODE_MARKDOWN_FIELD,
  EDITING_MODE_CONTENT_EDITOR,
  CLEAR_AUTOSAVE_ENTRY_EVENT,
} from '../../constants';
import MarkdownField from './field.vue';
import eventHub from './eventhub';

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
    setFacade: {
      type: Function,
      required: false,
      default: null,
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
    markdownDocsPath: {
      type: String,
      required: false,
      default: '',
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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
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

    this.$emit('input', this.markdown);
    this.saveDraft();

    this.setFacade?.({
      getValue: () => this.getValue(),
      setValue: (val) => this.setValue(val),
    });

    eventHub.$on(CLEAR_AUTOSAVE_ENTRY_EVENT, this.clearDraft);
  },
  beforeDestroy() {
    eventHub.$off(CLEAR_AUTOSAVE_ENTRY_EVENT, this.clearDraft);
  },
  methods: {
    getValue() {
      return this.markdown;
    },
    setValue(value) {
      this.markdown = value;
      this.$emit('input', value);

      this.saveDraft();
      this.autosizeTextarea();
    },
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
      const url = setUrlParams(
        { render_quick_actions: this.supportsQuickActions },
        joinPaths(window.location.origin, gon.relative_url_root, this.renderMarkdownPath),
      );
      return axios.post(url, { text: markdown }).then(({ data }) => data.body);
    },
    onEditingModeChange(editingMode) {
      this.editingMode = editingMode;
      this.notifyEditingModeChange(editingMode);
    },
    onEditingModeRestored(editingMode) {
      if (editingMode === EDITING_MODE_CONTENT_EDITOR && !this.enableContentEditor) {
        this.editingMode = EDITING_MODE_MARKDOWN_FIELD;
        return;
      }

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
    clearDraft(key) {
      if (!this.autosaveKey || key !== this.autosaveKey) return;
      clearDraft(this.autosaveKey);
    },
    togglePreview(value) {
      if (this.editingMode === EDITING_MODE_MARKDOWN_FIELD) {
        this.$refs.markdownField.previewMarkdown = value;
      }
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
      :value="editingMode"
      as-string
      storage-key="gl-markdown-editor-mode"
      @input="onEditingModeRestored"
    />
    <markdown-field
      v-if="!isContentEditorActive"
      ref="markdownField"
      v-bind="$attrs"
      data-testid="markdown-field"
      :markdown-preview-path="renderMarkdownPath"
      can-attach-file
      :textarea-value="markdown"
      :uploads-path="uploadsPath"
      :enable-autocomplete="enableAutocomplete"
      :autocomplete-data-sources="autocompleteDataSources"
      :markdown-docs-path="markdownDocsPath"
      :quick-actions-docs-path="quickActionsDocsPath"
      :show-content-editor-switcher="enableContentEditor"
      :drawio-enabled="drawioEnabled"
      @enableContentEditor="onEditingModeChange('contentEditor')"
      @handleSuggestDismissed="() => $emit('handleSuggestDismissed')"
    >
      <template #textarea>
        <textarea
          v-bind="formFieldProps"
          ref="textarea"
          :value="markdown"
          class="note-textarea js-gfm-input markdown-area"
          dir="auto"
          :data-supports-quick-actions="supportsQuickActions"
          :data-qa-selector="formFieldProps['data-qa-selector'] || 'markdown_editor_form_field'"
          :disabled="disabled"
          @input="updateMarkdownFromMarkdownField"
          @keydown="$emit('keydown', $event)"
        >
        </textarea>
      </template>
    </markdown-field>
    <div v-else>
      <content-editor
        ref="contentEditor"
        :render-markdown="renderMarkdown"
        :uploads-path="uploadsPath"
        :markdown="markdown"
        :quick-actions-docs-path="quickActionsDocsPath"
        :autofocus="contentEditorAutofocused"
        :placeholder="formFieldProps.placeholder"
        :drawio-enabled="drawioEnabled"
        :enable-autocomplete="enableAutocomplete"
        :autocomplete-data-sources="autocompleteDataSources"
        :editable="!disabled"
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
