<script>
export default {
  name: 'ShowMlModelVersionApp',
  components: {},
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>{{ modelVersion.model.name }} - {{ modelVersion.version }}</div>
</template>
