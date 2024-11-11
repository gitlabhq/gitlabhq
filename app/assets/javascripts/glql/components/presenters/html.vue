<script>
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'HtmlPresenter',
  directives: {
    SafeHtml,
  },
  props: {
    data: {
      required: true,
      type: String,
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>
<template>
  <div v-safe-html:[$options.safeHtmlConfig]="data"></div>
</template>
