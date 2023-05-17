<script>
import { GlFormInput } from '@gitlab/ui';
import setupCollapsibleInputs from '~/snippet/collapsible_input';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  components: {
    GlFormInput,
    MarkdownField,
  },
  props: {
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  mounted() {
    setupCollapsibleInputs();
  },
};
</script>
<template>
  <div class="form-group js-description-input">
    <label for="snippet-description">{{ s__('Snippets|Description (optional)') }}</label>
    <div class="js-collapsible-input">
      <div class="js-collapsed" :class="{ 'd-none': value }">
        <gl-form-input
          class="form-control"
          :placeholder="s__('Snippets|Describe what your snippet does or how to use it…')"
          data-qa-selector="description_placeholder"
        />
      </div>
      <markdown-field
        class="js-expanded"
        :class="{ 'd-none': !value }"
        :add-spacing-classes="false"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :textarea-value="value"
      >
        <template #textarea>
          <textarea
            id="snippet-description"
            ref="textarea"
            :value="value"
            class="note-textarea js-gfm-input js-autosize markdown-area"
            dir="auto"
            data-qa-selector="snippet_description_field"
            data-supports-quick-actions="false"
            :aria-label="__('Description')"
            :placeholder="__('Write a comment or drag your files here…')"
            v-bind="$attrs"
            @input="$emit('input', $event.target.value)"
          >
          </textarea>
        </template>
      </markdown-field>
    </div>
  </div>
</template>
