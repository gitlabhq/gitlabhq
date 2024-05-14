<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';

export default {
  components: {
    MarkdownFieldView,
  },
  directives: {
    SafeHtml,
  },
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>
<template>
  <markdown-field-view data-testid="snippet-description-content">
    <div
      v-safe-html:[$options.safeHtmlConfig]="description"
      class="md js-snippet-description"
    ></div>
  </markdown-field-view>
</template>
