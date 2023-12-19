<script>
import DownloadViewer from './viewers/download_viewer.vue';
import ImageViewer from './viewers/image_viewer.vue';
import MarkdownViewer from './viewers/markdown_viewer.vue';

export default {
  components: {
    MarkdownViewer,
    ImageViewer,
    DownloadViewer,
  },
  props: {
    content: {
      type: [String, ArrayBuffer],
      default: '',
      required: false,
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
    commitSha: {
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
    images: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <div class="preview-container">
    <image-viewer v-if="type === 'image'" :path="path" :file-size="fileSize" />
    <markdown-viewer
      v-if="type === 'markdown'"
      :content="content"
      :commit-sha="commitSha"
      :file-path="filePath"
      :project-path="projectPath"
      :images="images"
    />
    <download-viewer
      v-if="!type && path"
      :path="path"
      :file-path="filePath"
      :file-size="fileSize"
    />
  </div>
</template>
