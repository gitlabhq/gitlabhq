<script>
import { __, s__ } from '~/locale';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

export default {
  components: {
    MarkdownEditor,
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
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      formFieldProps: {
        id: 'snippet-description',
        name: 'snippet-description',
        placeholder: s__('Snippets|Describe what your snippet does or how to use it…'),
        'data-testid': 'snippet-description-field',
        'aria-label': __('Description'),
      },
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
  },
};
</script>
<template>
  <div class="form-group">
    <div class="common-note-form">
      <label for="snippet-description">{{ s__('Snippets|Description (optional)') }}</label>
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
      />
    </div>
  </div>
</template>
