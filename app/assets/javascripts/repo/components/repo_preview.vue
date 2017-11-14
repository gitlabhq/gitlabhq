<script>
import { mapGetters } from 'vuex';
import htmlPreview from './viewers/html.vue';

export default {
  components: {
    htmlPreview,
  },
  computed: {
    ...mapGetters([
      'activeFileCurrentViewer',
    ]),
    previewComponent() {
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
