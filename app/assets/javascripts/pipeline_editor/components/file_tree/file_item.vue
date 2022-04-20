<script>
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  name: 'PipelineEditorFileItem',
  components: {
    FileIcon,
  },
  props: {
    fileName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-py-2 gl-px-3 gl-rounded-base">
    <span class="file-row-name" :title="fileName">
      <file-icon class="file-row-icon" :file-name="fileName" />
      <span>{{ fileName }}</span>
    </span>
  </div>
</template>
