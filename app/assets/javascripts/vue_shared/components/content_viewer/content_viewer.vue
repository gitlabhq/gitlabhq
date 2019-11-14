<script>
import MarkdownViewer from './viewers/markdown_viewer.vue';
import ImageViewer from './viewers/image_viewer.vue';
import DownloadViewer from './viewers/download_viewer.vue';

export default {
  props: {
    content: {
      type: String,
      default: '',
    },
    path: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number,
      required: false,
      default: 0,
    },
    filePath: {
      type: String,
      required: false,
      default: '',
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    type: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    viewer() {
      if (!this.path) return null;
      if (!this.type) return DownloadViewer;

      switch (this.type) {
        case 'markdown':
          return MarkdownViewer;
        case 'image':
          return ImageViewer;
        default:
          return DownloadViewer;
      }
    },
  },
};
</script>

<template>
  <div class="preview-container">
    <component
      :is="viewer"
      :path="path"
      :file-path="filePath"
      :file-size="fileSize"
      :project-path="projectPath"
      :content="content"
    />
  </div>
</template>
