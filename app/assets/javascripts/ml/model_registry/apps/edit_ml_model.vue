<script>
import ModelEdit from '../components/model_edit.vue';

export default {
  name: 'EditMlModel',
  components: {
    ModelEdit,
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
    modelPath: {
      type: String,
      required: true,
    },
    modelId: {
      type: Number,
      required: true,
    },
    modelName: {
      type: String,
      required: true,
    },
    modelDescription: {
      type: String,
      required: true,
    },
  },
  computed: {
    model() {
      return {
        id: this.modelId,
        name: this.modelName,
        description: this.modelDescription,
      };
    },
  },
};
</script>

<template>
  <model-edit
    v-if="canWriteModelRegistry"
    :model="model"
    :project-path="projectPath"
    :markdown-preview-path="markdownPreviewPath"
    :model-path="modelPath"
    :disable-attachments="false"
  />
</template>
