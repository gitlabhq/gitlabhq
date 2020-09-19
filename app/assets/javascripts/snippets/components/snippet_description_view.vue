<script>
/* eslint-disable vue/no-v-html */
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';

export default {
  components: {
    MarkdownFieldView,
  },
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <markdown-field-view class="snippet-description" data-qa-selector="snippet_description_content">
    <div class="md js-snippet-description" v-html="description"></div>
  </markdown-field-view>
</template>
