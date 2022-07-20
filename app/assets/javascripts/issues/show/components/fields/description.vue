<script>
import markdownField from '~/vue_shared/components/markdown/field.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import updateMixin from '../../mixins/update';

export default {
  components: {
    markdownField,
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
  computed: {
    quickActionsDocsPath() {
      return helpPagePath('user/project/quick_actions');
    },
  },
  mounted() {
    this.$refs.textarea.focus();
  },
};
</script>

<template>
  <div class="common-note-form">
    <label class="sr-only" for="issue-description">{{ __('Description') }}</label>
    <markdown-field
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
