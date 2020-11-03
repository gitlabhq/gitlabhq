<script>
import EditorLite from '~/vue_shared/components/editor_lite.vue';

export default {
  components: {
    EditorLite,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div class="gl-border-solid gl-border-gray-100 gl-border-1">
    <editor-lite
      v-model="value"
      file-name="*.yml"
      :editor-options="{ readOnly: true }"
      @editor-ready="$emit('editor-ready')"
    />
  </div>
</template>
