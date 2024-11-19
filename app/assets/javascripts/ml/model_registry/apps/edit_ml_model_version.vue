<script>
import ModelVersionEdit from '../components/model_version_edit.vue';

export default {
  name: 'EditMlModelVersion',
  components: {
    ModelVersionEdit,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    canWriteModelRegistry: {
      type: Boolean,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    modelVersionPath: {
      type: String,
      required: true,
    },
    modelGid: {
      type: String,
      required: true,
    },
    modelVersionVersion: {
      type: String,
      required: true,
    },
    modelVersionDescription: {
      type: String,
      required: true,
    },
  },
  computed: {
    modelWithModelVersion() {
      return {
        id: this.modelGid,
        version: {
          version: this.modelVersionVersion,
          description: this.modelVersionDescription,
        },
      };
    },
  },
};
</script>

<template>
  <model-version-edit
    v-if="canWriteModelRegistry"
    :model-with-version="modelWithModelVersion"
    :project-path="projectPath"
    :markdown-preview-path="markdownPreviewPath"
    :model-version-path="modelVersionPath"
    :disable-attachments="false"
  />
</template>
