<script>
import { __ } from '~/locale';
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
      :form-field-props="formFieldProps"
      :quick-actions-docs-path="quickActionsDocsPath"
      :enable-autocomplete="enableAutocomplete"
      supports-quick-actions
      autofocus
      @input="$emit('input', $event)"
      @keydown.meta.enter="updateIssuable"
      @keydown.ctrl.enter="updateIssuable"
    />
    <markdown-field
      v-else
      class="gl-mt-3"
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :quick-actions-docs-path="quickActionsDocsPath"
      :can-attach-file="canAttachFile"
      :enable-autocomplete="enableAutocomplete"
      :textarea-value="value"
    >
      <template #textarea>
        <textarea
          v-bind="formFieldProps"
          ref="textarea"
          :value="value"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          data-qa-selector="description_field"
          dir="auto"
          data-supports-quick-actions="true"
          @input="$emit('input', $event.target.value)"
          @keydown.meta.enter="updateIssuable"
          @keydown.ctrl.enter="updateIssuable"
        >
        </textarea>
      </template>
    </markdown-field>
  </div>
</template>
