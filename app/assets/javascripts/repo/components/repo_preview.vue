<script>
import { mapGetters } from 'vuex';
import errorPreview from './viewers/error.vue';
import htmlPreview from './viewers/html.vue';

export default {
  components: {
    errorPreview,
    htmlPreview,
  },
  computed: {
    ...mapGetters([
      'activeFileCurrentViewer',
    ]),
    previewComponent() {
      if (this.activeFileCurrentViewer.renderError) return 'error-preview';
      if (this.activeFileCurrentViewer.serverRender) return 'html-preview';

      const componentName = this.$options.components[`${this.activeFileCurrentViewer.name}Preview`];

      if (componentName) {
        return componentName;
      }

      return 'html-preview';
    },
  },
};
</script>

<template>
  <div class="blob-viewer-container">
    <component
      :is="previewComponent"
    />
  </div>
</template>
