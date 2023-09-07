<script>
import { diffViewerModes, diffModes } from '~/ide/constants';
import DownloadDiffViewer from './viewers/download_diff_viewer.vue';
import ImageDiffViewer from './viewers/image_diff_viewer.vue';
import ModeChanged from './viewers/mode_changed.vue';
import RenamedFile from './viewers/renamed.vue';

export default {
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffMode: {
      type: String,
      required: true,
    },
    diffViewerMode: {
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
    newSize: {
      type: Number,
      required: false,
      default: 0,
    },
    oldPath: {
      type: String,
      required: true,
    },
    oldSha: {
      type: String,
      required: true,
    },
    oldSize: {
      type: Number,
      required: false,
      default: 0,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    aMode: {
      type: String,
      required: false,
      default: null,
    },
    bMode: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    viewer() {
      if (this.diffViewerMode === diffViewerModes.renamed) {
        return RenamedFile;
      }
      if (this.diffMode === diffModes.mode_changed) {
        return ModeChanged;
      }

      if (!this.newPath) return null;

      switch (this.diffViewerMode) {
        case diffViewerModes.image:
          return ImageDiffViewer;
        default:
          return DownloadDiffViewer;
      }
    },
    basePath() {
      // We might get the project path from rails with the relative url already set up
      return this.projectPath.indexOf('/') === 0 ? '' : `${gon.relative_url_root}/`;
    },
    fullOldPath() {
      return `${this.basePath}${this.projectPath}/-/raw/${this.oldSha}/${this.oldPath}`;
    },
    fullNewPath() {
      return `${this.basePath}${this.projectPath}/-/raw/${this.newSha}/${this.newPath}`;
    },
  },
};
</script>

<template>
  <div v-if="viewer" class="diff-file preview-container">
    <component
      :is="viewer"
      :diff-file="diffFile"
      :diff-mode="diffMode"
      :new-path="fullNewPath"
      :old-path="fullOldPath"
      :old-size="oldSize"
      :new-size="newSize"
      :project-path="projectPath"
      :a-mode="aMode"
      :b-mode="bMode"
    >
      <template #image-overlay="{ renderedWidth, renderedHeight }">
        <slot
          :rendered-width="renderedWidth"
          :rendered-height="renderedHeight"
          name="image-overlay"
        ></slot>
      </template>
    </component>
    <slot></slot>
  </div>
</template>
