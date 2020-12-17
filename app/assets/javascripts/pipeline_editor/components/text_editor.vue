<script>
import EditorLite from '~/vue_shared/components/editor_lite.vue';

export default {
  components: {
    EditorLite,
  },
};
</script>
<template>
  <div class="gl-border-solid gl-border-gray-100 gl-border-1">
    <editor-lite file-name="*.yml" v-bind="$attrs" v-on="$listeners" />
  </div>
</template>
