<script>
import RepoStore from '../stores/repo_store';

export default {
  data: () => RepoStore,
  
  computed: {
    html() {
      return this.activeFile.html;
    }
  },

  watch: {

    html() {
      this.$nextTick(() => {
        $(this.$el).find('.file-content').syntaxHighlight();
      });
    }

  }
}
</script>

<template>
<div v-html="activeFile.html"></div>
</template>
