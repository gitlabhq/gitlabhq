<script>
import Store from '../stores/repo_store';

export default {
  data: () => Store,
  mounted() {
    $(this.$el).find('.file-content').syntaxHighlight();
  },
  computed: {
    html() {
      return this.activeFile.html;
    },
  },

  watch: {
    html() {
      this.$nextTick(() => {
        $(this.$el).find('.file-content').syntaxHighlight();
      });
    },
  },
};
</script>

<template>
<div v-html="activeFile.html"></div>
</template>
