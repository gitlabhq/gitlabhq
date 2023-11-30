<script>
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import ModelVersionDetail from '../components/model_version_detail.vue';

export default {
  name: 'ShowMlModelVersionApp',
  components: {
    ModelVersionDetail,
    TitleArea,
  },
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    title() {
      return `${this.modelVersion.model.name} / ${this.modelVersion.version}`;
    },
  },
};
</script>

<template>
  <div>
    <title-area :title="title" />
    <model-version-detail :model-version="modelVersion" />
  </div>
</template>
