<script>
import DownloadViewer from '../../content_viewer/viewers/download_viewer.vue';
import { diffModes } from '../constants';

export default {
  components: {
    DownloadViewer,
  },
  props: {
    diffMode: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
    oldPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  diffModes,
};
</script>

<template>
  <div class="diff-file-container">
    <div class="diff-viewer">
      <div v-if="diffMode === $options.diffModes.replaced" class="two-up view row">
        <div class="col-sm-6 deleted">
          <download-viewer :path="oldPath" :project-path="projectPath" />
        </div>
        <div class="col-sm-6 added">
          <download-viewer :path="newPath" :project-path="projectPath" />
        </div>
      </div>
      <div v-else-if="diffMode === $options.diffModes.new" class="added">
        <download-viewer :path="newPath" :project-path="projectPath" />
      </div>
      <div v-else class="deleted">
        <download-viewer :path="oldPath" :project-path="projectPath" />
      </div>
    </div>
  </div>
</template>
