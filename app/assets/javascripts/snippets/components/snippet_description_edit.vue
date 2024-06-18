<script>
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  components: {
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
};
</script>
<template>
  <div class="form-group">
    <label for="snippet-description">{{ s__('Snippets|Description (optional)') }}</label>
    <markdown-field
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
          rows="3"
          class="note-textarea js-gfm-input js-autosize markdown-area !gl-min-h-0"
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
</template>
