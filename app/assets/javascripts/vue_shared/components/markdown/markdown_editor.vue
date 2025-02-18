<script>
import { GlAlert } from '@gitlab/ui';
import Autosize from 'autosize';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { updateDraft, clearDraft, getDraft } from '~/lib/utils/autosave';
import { setUrlParams, joinPaths } from '~/lib/utils/url_utility';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  EDITING_MODE_KEY,
  EDITING_MODE_MARKDOWN_FIELD,
  EDITING_MODE_CONTENT_EDITOR,
  CLEAR_AUTOSAVE_ENTRY_EVENT,
} from '../../constants';
import MarkdownField from './field.vue';
import eventHub from './eventhub';

async function sleep(t = 10) {
  return new Promise((resolve) => {
    setTimeout(resolve, t);
  });
}

async function waitFor(getEl, interval = 10, timeout = 2000) {
  if (timeout <= 0) return null;

  const el = getEl();
  if (el) return el;

  await sleep(interval);
  return waitFor(getEl, timeout - interval);
}

export default {
  components: {
    GlAlert,
    MarkdownField,
    LocalStorageSync,
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
      default: () => window.uploads_path || '',
    },
    enableContentEditor: {
      type: Boolean,
      required: false,
      default: true,
    },
    formFieldProps: {
      type: Object,
      required: true,
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
    disableAttachments: {
      type: Boolean,
      required: false,
      default: false,
    },
    codeSuggestionsConfig: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    noteableType: {
      type: String,
      required: false,
      default: '',
    },
    restrictedToolBarItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    restoreFromAutosave: {
      type: Boolean,
      required: false,
      default: false,
    },
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    let editingMode;
    switch (window.gon?.text_editor) {
      case 'rich_text_editor':
        editingMode = EDITING_MODE_CONTENT_EDITOR;
        break;
      case 'plain_text_editor':
        editingMode = EDITING_MODE_MARKDOWN_FIELD;
        break;
      default:
        editingMode =
          localStorage.getItem(this.$options.EDITING_MODE_KEY) || EDITING_MODE_MARKDOWN_FIELD;
    }

    const autosaveValue = this.autosaveKey ? getDraft(this.autosaveKey) : '';
    const initialValue = this.restoreFromAutosave ? autosaveValue : this.value;

    return {
      alert: null,
      markdown: initialValue || autosaveValue || '',
      editingMode,
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
    markdownFieldRestrictedToolBarItems() {
      const restrictAttachments = this.disableAttachments ? ['attach-file'] : [];

      return [...this.restrictedToolBarItems, ...restrictAttachments];
    },
    isDefaultEditorEnabled() {
      return ['plain_text_editor', 'rich_text_editor'].includes(window.gon?.text_editor);
    },
  },
  watch: {
    value: 'updateValue',
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
      this.$emit('input', value);
      this.updateValue(value);
    },
    updateValue(value) {
      this.markdown = value;
      this.saveDraft();
      this.autosizeTextarea();
    },
    append(value) {
      if (!value) {
        this.focus();
        return;
      }
      const newValue = [this.markdown.trim(), value].filter(Boolean).join('\n\n');
      this.updateValue(`${newValue}\n\n`);
      this.$nextTick(() => {
        this.focus();
      });
    },
    setTemplate(template, force = false) {
      if (!this.markdown || force) {
        this.setValue(template);
      } else {
        const dismiss = () => {
          this.alert = null;
        };
        this.alert = {
          message: this.$options.i18n.applyTemplateAlert.message,
          variant: 'warning',
          primaryButtonText: this.$options.i18n.applyTemplateAlert.primaryButtonText,
          secondaryButtonText: this.$options.i18n.applyTemplateAlert.secondaryButtonText,
          primaryAction: () => {
            this.setValue(template, true);
            dismiss();
          },
          secondaryAction: dismiss,
          dismiss,
        };
      }
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
    },
    renderMarkdown(markdown) {
      const url = setUrlParams(
        { render_quick_actions: this.supportsQuickActions },
        joinPaths(window.location.origin, this.renderMarkdownPath),
      );
      return axios
        .post(url, { text: markdown })
        .then(({ data: { html, body, ...otherData } = {} } = {}) => ({
          body: body || html,
          ...otherData,
        }));
    },
    onEditingModeChange(editingMode) {
      this.editingMode = editingMode;
      this.notifyEditingModeChange(editingMode);
    },
    onEditingModeRestored(editingMode) {
      if (!this.isDefaultEditorEnabled) return;
      if (editingMode === EDITING_MODE_CONTENT_EDITOR && !this.enableContentEditor) {
        this.editingMode = EDITING_MODE_MARKDOWN_FIELD;
        return;
      }

      this.editingMode = editingMode;
      this.$emit(editingMode);
      this.notifyEditingModeChange(editingMode);
    },
    async notifyEditingModeChange(editingMode) {
      this.$emit(editingMode);

      const componentToFocus =
        editingMode === EDITING_MODE_CONTENT_EDITOR
          ? () => this.$refs.contentEditor
          : () => this.$refs.textarea;

      (await waitFor(componentToFocus)).focus();
    },
    autofocusTextarea() {
      if (this.autofocus && this.editingMode === EDITING_MODE_MARKDOWN_FIELD) {
        this.$refs.textarea.focus();
        this.setEditorAsAutofocused();
      }
    },
    focus() {
      if (this.editingMode === EDITING_MODE_MARKDOWN_FIELD) {
        this.$refs.textarea.focus();
      } else {
        this.$refs.contentEditor.focus();
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
    onKeydown(event) {
      const isModifierKey = event.ctrlKey || event.metaKey;
      if (isModifierKey && event.key === 'k') {
        event.preventDefault();
      }
      this.$emit('keydown', event);
    },
  },
  EDITING_MODE_KEY,
  i18n: {
    applyTemplateAlert: {
      message: __(
        'Applying a template will replace the existing content. Any changes you have made will be lost.',
      ),
      primaryButtonText: __('Apply template'),
      secondaryButtonText: __('Cancel'),
    },
  },
};
</script>
<template>
  <div class="md-area-wrapper gl-rounded-lg !gl-px-0">
    <local-storage-sync
      v-if="!isDefaultEditorEnabled"
      :value="editingMode"
      as-string
      :storage-key="$options.EDITING_MODE_KEY"
      @input="onEditingModeRestored"
    />
    <gl-alert
      v-if="alert"
      class="gl-mb-4"
      :variant="alert.variant"
      :primary-button-text="alert.primaryButtonText"
      :secondary-button-text="alert.secondaryButtonText"
      @primaryAction="alert.primaryAction"
      @secondaryAction="alert.secondaryAction"
      @dismiss="alert.dismiss"
    >
      {{ alert.message }}
    </gl-alert>
    <markdown-field
      v-if="!isContentEditorActive"
      ref="markdownField"
      v-bind="$attrs"
      data-testid="markdown-field"
      :markdown-preview-path="renderMarkdownPath"
      :new-comment-template-paths="newCommentTemplatePaths"
      :can-attach-file="!disableAttachments"
      :can-suggest="codeSuggestionsConfig.canSuggest"
      :line="codeSuggestionsConfig.line"
      :lines="codeSuggestionsConfig.lines"
      :show-suggest-popover="codeSuggestionsConfig.showPopover"
      :textarea-value="markdown"
      :uploads-path="uploadsPath"
      :enable-autocomplete="enableAutocomplete"
      :autocomplete-data-sources="autocompleteDataSources"
      :markdown-docs-path="markdownDocsPath"
      :supports-quick-actions="supportsQuickActions"
      :show-content-editor-switcher="enableContentEditor"
      :drawio-enabled="drawioEnabled"
      :restricted-tool-bar-items="markdownFieldRestrictedToolBarItems"
      :remove-border="true"
      @enableContentEditor="onEditingModeChange('contentEditor')"
      @handleSuggestDismissed="() => $emit('handleSuggestDismissed')"
    >
      <template #header-buttons><slot name="header-buttons"></slot></template>
      <template #toolbar><slot name="toolbar"></slot></template>
      <template #textarea>
        <textarea
          v-bind="formFieldProps"
          ref="textarea"
          :value="markdown"
          class="note-textarea js-gfm-input markdown-area"
          dir="auto"
          :data-can-suggest="codeSuggestionsConfig.canSuggest"
          :data-noteable-type="noteableType"
          :data-supports-quick-actions="supportsQuickActions"
          :data-testid="formFieldProps['data-testid'] || 'markdown-editor-form-field'"
          :disabled="disabled"
          @input="updateMarkdownFromMarkdownField"
          @keydown="$emit('keydown', $event)"
        ></textarea>
      </template>
    </markdown-field>
    <div v-else>
      <content-editor
        ref="contentEditor"
        :render-markdown="renderMarkdown"
        :markdown-docs-path="markdownDocsPath"
        :new-comment-template-paths="newCommentTemplatePaths"
        :uploads-path="uploadsPath"
        :markdown="markdown"
        :supports-quick-actions="supportsQuickActions"
        :autofocus="contentEditorAutofocused"
        :placeholder="formFieldProps.placeholder"
        :drawio-enabled="drawioEnabled"
        :enable-autocomplete="enableAutocomplete"
        :autocomplete-data-sources="autocompleteDataSources"
        :editable="!disabled"
        :disable-attachments="disableAttachments"
        :code-suggestions-config="codeSuggestionsConfig"
        :data-testid="formFieldProps['data-testid'] || 'markdown-editor-form-field'"
        @initialized="setEditorAsAutofocused"
        @change="updateMarkdownFromContentEditor"
        @keydown="onKeydown"
        @enableMarkdownEditor="onEditingModeChange('markdownField')"
      >
        <template #header-buttons><slot name="header-buttons"></slot></template>
        <template #toolbar><slot name="toolbar"></slot></template>
      </content-editor>
      <input v-bind="formFieldProps" :value="markdown" type="hidden" />
    </div>
  </div>
</template>
