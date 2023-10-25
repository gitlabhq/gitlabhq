<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { __ } from '~/locale';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { ISSUE_NOTEABLE_TYPE } from '~/notes/constants';
import updateMixin from '../../mixins/update';

export default {
  components: {
    MarkdownEditor,
  },
  mixins: [updateMixin],
  props: {
    value: {
      type: String,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      formFieldProps: {
        id: 'issue-description',
        name: 'issue-description',
        placeholder: __('Write a comment or drag your files here…'),
        'aria-label': __('Description'),
      },
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
  },
  mounted() {
    this.focus();
  },
  methods: {
    focus() {
      this.$refs.textarea?.focus();
    },
    saveIssuable() {
      trackSavedUsingEditor(this.$refs.markdownEditor.isContentEditorActive, ISSUE_NOTEABLE_TYPE);
      this.updateIssuable();
    },
  },
};
</script>

<template>
  <div class="common-note-form">
    <label class="sr-only" for="issue-description">{{ __('Description') }}</label>
    <markdown-editor
      ref="markdownEditor"
      class="gl-mt-3"
      :value="value"
      :render-markdown-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :form-field-props="formFieldProps"
      :enable-autocomplete="enableAutocomplete"
      :autocomplete-data-sources="autocompleteDataSources"
      supports-quick-actions
      autofocus
      @input="$emit('input', $event)"
      @keydown.meta.enter="saveIssuable"
      @keydown.ctrl.enter="saveIssuable"
    />
  </div>
</template>
