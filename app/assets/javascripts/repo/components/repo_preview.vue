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
  <div>
    <div v-if="!activeFile.render_error" v-html="activeFile.html" />
    <div v-if="activeFile.render_error" class="vertical-center render-error">
      <p class="text-center">The source could not be displayed because it is too large. You can <a :href="activeFile.raw_path">download</a> it instead.</p>
    </div>
  </div>
</template>
