<script>
import { viewerInformationForPath } from '../content_viewer/lib/viewer_utils';
import ImageDiffViewer from './viewers/image_diff_viewer.vue';
import DownloadDiffViewer from './viewers/download_diff_viewer.vue';

export default {
  props: {
    diffMode: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
    newSha: {
      type: String,
      required: true,
    },
    oldPath: {
      type: String,
      required: true,
    },
    oldSha: {
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
      if (!this.newPath) return null;

      const previewInfo = viewerInformationForPath(this.newPath);
      if (!previewInfo) return DownloadDiffViewer;

      switch (previewInfo.id) {
        case 'image':
          return ImageDiffViewer;
        default:
          return DownloadDiffViewer;
      }
    },
    fullOldPath() {
      return `${gon.relative_url_root}/${this.projectPath}/raw/${this.oldSha}/${this.oldPath}`;
    },
    fullNewPath() {
      return `${gon.relative_url_root}/${this.projectPath}/raw/${this.newSha}/${this.newPath}`;
    },
  },
};
</script>

<template>
  <div
    v-if="viewer"
    class="diff-file preview-container">
    <component
      :is="viewer"
      :diff-mode="diffMode"
      :new-path="fullNewPath"
      :old-path="fullOldPath"
      :project-path="projectPath"
    />
  </div>
</template>
