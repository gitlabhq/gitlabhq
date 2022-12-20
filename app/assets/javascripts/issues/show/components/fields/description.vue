<script>
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import glFeaturesFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import updateMixin from '../../mixins/update';

export default {
  components: {
    MarkdownField,
    MarkdownEditor,
  },
  mixins: [updateMixin, glFeaturesFlagMixin()],
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
  computed: {
    quickActionsDocsPath() {
      return helpPagePath('user/project/quick_actions');
    },
  },
  mounted() {
    this.focus();
  },
  methods: {
    focus() {
      this.$refs.textarea?.focus();
    },
  },
};
</script>

<template>
  <div class="common-note-form">
    <label class="sr-only" for="issue-description">{{ __('Description') }}</label>
    <markdown-editor
      v-if="glFeatures.contentEditorOnIssues"
      class="gl-mt-3"
      :value="value"
      :render-markdown-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :form-field-aria-label="__('Description')"
      :form-field-placeholder="__('Write a comment or drag your files here…')"
      form-field-id="issue-description"
      form-field-name="issue-description"
      :quick-actions-docs-path="quickActionsDocsPath"
      :enable-autocomplete="enableAutocomplete"
      supports-quick-actions
      use-bottom-toolbar
      autofocus
      @input="$emit('input', $event)"
      @keydown.meta.enter="updateIssuable"
      @keydown.ctrl.enter="updateIssuable"
    />
    <markdown-field
      v-else
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :quick-actions-docs-path="quickActionsDocsPath"
      :can-attach-file="canAttachFile"
      :enable-autocomplete="enableAutocomplete"
      :textarea-value="value"
    >
      <template #textarea>
        <textarea
          id="issue-description"
          ref="textarea"
          :value="value"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          data-qa-selector="description_field"
          dir="auto"
          data-supports-quick-actions="true"
          :aria-label="__('Description')"
          :placeholder="__('Write a comment or drag your files here…')"
          @input="$emit('input', $event.target.value)"
          @keydown.meta.enter="updateIssuable"
          @keydown.ctrl.enter="updateIssuable"
        >
        </textarea>
      </template>
    </markdown-field>
  </div>
</template>
