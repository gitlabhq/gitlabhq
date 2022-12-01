<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import axios from '~/lib/utils/axios_utils';
import { EDITING_MODE_MARKDOWN_FIELD, EDITING_MODE_CONTENT_EDITOR } from '../../constants';
import MarkdownField from './field.vue';

export default {
  components: {
    MarkdownField,
    LocalStorageSync,
    GlSegmentedControl,
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
      switchEditingControlEnabled: true,
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
    enableSwitchEditingControl() {
      this.switchEditingControlEnabled = true;
    },
    disableSwitchEditingControl() {
      this.switchEditingControlEnabled = false;
    },
    renderMarkdown(markdown) {
      return axios.post(this.renderMarkdownPath, { text: markdown }).then(({ data }) => data.body);
    },
    onEditingModeChange(editingMode) {
      this.notifyEditingModeChange(editingMode);
    },
    onEditingModeRestored(editingMode) {
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
  switchEditingControlOptions: [
    { text: __('Source'), value: EDITING_MODE_MARKDOWN_FIELD },
    { text: __('Rich text'), value: EDITING_MODE_CONTENT_EDITOR },
  ],
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-start gl-mb-3">
      <gl-segmented-control
        v-model="editingMode"
        data-testid="toggle-editing-mode-button"
        data-qa-selector="editing_mode_button"
        class="gl-display-flex"
        :options="$options.switchEditingControlOptions"
        :disabled="!enableContentEditor || !switchEditingControlEnabled"
        @change="onEditingModeChange"
      />
    </div>
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
      class="bordered-box"
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
        @loading="disableSwitchEditingControl"
        @loadingSuccess="enableSwitchEditingControl"
        @loadingError="enableSwitchEditingControl"
        @keydown="$emit('keydown', $event)"
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
