<script>
import ModelVersionCreate from '../components/model_version_create.vue';

export default {
  name: 'NewMlModelVersion',
  components: {
    ModelVersionCreate,
  },
  provide() {
    return {
      maxAllowedFileSize: this.maxAllowedFileSize,
      latestVersion: this.latestVersion,
      modelGid: this.modelGid,
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    canWriteModelRegistry: {
      type: Boolean,
      required: false,
      default: false,
    },
    maxAllowedFileSize: {
      type: Number,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    latestVersion: {
      type: String,
      required: false,
      default: null,
    },
    modelGid: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <model-version-create
    v-if="canWriteModelRegistry"
    :project-path="projectPath"
    :markdown-preview-path="markdownPreviewPath"
  />
</template>
