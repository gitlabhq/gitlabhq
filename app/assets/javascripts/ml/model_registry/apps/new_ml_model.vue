<script>
import ModelCreate from '../components/model_create.vue';

export default {
  name: 'NewMlModel',
  components: {
    ModelCreate,
  },
  provide() {
    return {
      projectPath: this.projectPath,
      markdownPreviewPath: this.markdownPreviewPath,
    };
  },
  props: {
    indexModelsPath: {
      type: String,
      required: true,
    },
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
  },
};
</script>

<template>
  <model-create
    v-if="canWriteModelRegistry"
    :project-path="projectPath"
    :markdown-preview-path="markdownPreviewPath"
    :index-models-path="indexModelsPath"
  />
</template>
