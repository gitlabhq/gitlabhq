<script>
import { mapGetters } from 'vuex';
import htmlPreview from './viewers/html.vue';
import pdfPreview from './viewers/pdf.vue';
import stlPreview from './viewers/stl.vue';
import imagePreview from './viewers/image.vue';
import sketchPreview from './viewers/sketch.vue';

export default {
  components: {
    pdfPreview,
    htmlPreview,
    stlPreview,
    imagePreview,
    sketchPreview,
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
