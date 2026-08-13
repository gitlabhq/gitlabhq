<script>
import { diffViewerModes, diffModes } from '~/ide/constants';
import { projectRawPath } from '~/lib/utils/path_helpers/repository';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import DownloadDiffViewer from './viewers/download_diff_viewer.vue';
import ImageDiffViewer from './viewers/image_diff_viewer.vue';
import ModeChanged from './viewers/mode_changed.vue';
import RenamedFile from './viewers/renamed.vue';

export default {
  name: 'DiffViewer',
  mixins: [glSlotsMixin],
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
    fullOldPath() {
      return this.buildRawPath(this.oldSha, this.oldPath);
    },
    fullNewPath() {
      return this.buildRawPath(this.newSha, this.newPath);
    },
  },
  methods: {
    buildRawPath(sha, path) {
      if (!this.projectPath) return '';

      return projectRawPath(this.projectPath, `${sha}/${path}`);
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
      <template
        v-if="glSlots()['image-overlay']"
        #image-overlay="{ width, height, renderedWidth, renderedHeight }"
      >
        <slot
          :width="width"
          :height="height"
          :rendered-width="renderedWidth"
          :rendered-height="renderedHeight"
          name="image-overlay"
        ></slot>
      </template>
    </component>
    <slot></slot>
  </div>
</template>
