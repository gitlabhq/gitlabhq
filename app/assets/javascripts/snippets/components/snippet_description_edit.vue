<script>
import { GlFormTextarea } from '@gitlab/ui';
import setupCollapsibleInputs from '~/snippet/collapsible_input';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  components: {
    GlFormTextarea,
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
        <gl-form-textarea
          class="form-control"
          rows="2"
          :no-resize="true"
          :placeholder="s__('Snippets|Describe what your snippet does or how to use it…')"
          data-testid="description-placeholder"
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
            data-testid="snippet-description-field"
            data-supports-quick-actions="false"
            :aria-label="__('Description')"
            :placeholder="s__('Snippets|Describe what your snippet does or how to use it…')"
            v-bind="$attrs"
            @input="$emit('input', $event.target.value)"
          >
          </textarea>
        </template>
      </markdown-field>
    </div>
  </div>
</template>
