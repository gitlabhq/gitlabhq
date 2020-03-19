<script>
import { GlFormInput } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import setupCollapsibleInputs from '~/snippet/collapsible_input';

export default {
  components: {
    GlFormInput,
    MarkdownField,
  },
  props: {
    description: {
      type: String,
      default: '',
      required: false,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      text: this.description,
    };
  },
  mounted() {
    setupCollapsibleInputs();
  },
};
</script>
<template>
  <div class="form-group js-description-input">
    <label>{{ s__('Snippets|Description (optional)') }}</label>
    <div class="js-collapsible-input">
      <div class="js-collapsed" :class="{ 'd-none': text }">
        <gl-form-input
          class="form-control"
          :placeholder="
            s__(
              'Snippets|Optionally add a description about what your snippet does or how to use it…',
            )
          "
          data-qa-selector="description_placeholder"
        />
      </div>
      <markdown-field
        class="js-expanded"
        :class="{ 'd-none': !text }"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
      >
        <textarea
          id="snippet-description"
          slot="textarea"
          v-model="text"
          class="note-textarea js-gfm-input js-autosize markdown-area
            qa-description-textarea"
          dir="auto"
          data-supports-quick-actions="false"
          :aria-label="__('Description')"
          :placeholder="__('Write a comment or drag your files here…')"
        >
        </textarea>
      </markdown-field>
    </div>
  </div>
</template>
