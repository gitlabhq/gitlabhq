<script>
import ImageViewer from '../../../content_viewer/viewers/image_viewer.vue';

export default {
  components: {
    ImageViewer,
  },
  props: {
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
};
</script>

<template>
  <div class="two-up view row">
    <div class="col-sm-6 frame deleted">
      <image-viewer
        :path="oldPath"
        :project-path="projectPath"
      />
    </div>
    <div class="col-sm-6 frame added">
      <image-viewer
        :path="newPath"
        :project-path="projectPath"
      />
    </div>
  </div>
</template>
