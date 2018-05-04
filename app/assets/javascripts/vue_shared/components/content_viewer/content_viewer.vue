<script>
import { viewerInformationForPath } from './lib/viewer_utils';
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
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    viewer() {
      if (!this.path) return null;

      const previewInfo = viewerInformationForPath(this.path);
      if (!previewInfo) return DownloadViewer;

      switch (previewInfo.id) {
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
      :file-size="fileSize"
      :project-path="projectPath"
      :content="content"
    />
  </div>
</template>
