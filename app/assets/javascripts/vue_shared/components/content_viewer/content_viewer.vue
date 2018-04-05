<script>
import { viewerInformationForPath } from './lib/viewer_utils';
import MarkdownViewer from './viewers/markdown_viewer.vue';

export default {
  props: {
    content: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    viewer() {
      const previewInfo = viewerInformationForPath(this.path);
      switch (previewInfo.id) {
        case 'markdown':
          return MarkdownViewer;
        default:
          return null;
      }
    },
  },
};
</script>

<template>
  <div class="preview-container">
    <component
      :is="viewer"
      :project-path="projectPath"
      :content="content"
    />
  </div>
</template>
