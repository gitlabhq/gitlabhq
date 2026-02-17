<script>
import ImageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';

export default {
  name: 'ImageViewer',
  components: {
    ImageDiffViewer,
  },
  props: {
    imageData: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <image-diff-viewer
    :old-path="imageData.old_path"
    :new-path="imageData.new_path"
    :old-size="imageData.old_size ? parseInt(imageData.old_size, 10) : undefined"
    :new-size="imageData.new_size ? parseInt(imageData.new_size, 10) : undefined"
    :diff-mode="imageData.diff_mode"
    :encode-path="false"
  >
    <template #image-overlay="scope">
      <slot name="image-overlay" v-bind="scope"></slot>
    </template>
  </image-diff-viewer>
</template>
