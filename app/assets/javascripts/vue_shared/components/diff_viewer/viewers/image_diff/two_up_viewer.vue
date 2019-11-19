<script>
import ImageViewer from '../../../content_viewer/viewers/image_viewer.vue';

export default {
  components: {
    ImageViewer,
  },
  props: {
    newPath: {
      type: String,
      required: true,
    },
    oldPath: {
      type: String,
      required: true,
    },
    newSize: {
      type: Number,
      required: false,
      default: 0,
    },
    oldSize: {
      type: Number,
      required: false,
      default: 0,
    },
  },
};
</script>

<template>
  <div class="two-up view d-flex">
    <image-viewer
      :path="oldPath"
      :file-size="oldSize"
      :render-info="true"
      inner-css-classes="frame deleted"
      class="wrap w-50"
    />
    <image-viewer
      :path="newPath"
      :file-size="newSize"
      :render-info="true"
      :inner-css-classes="['frame', 'added']"
      class="wrap w-50"
    >
      <slot slot="image-overlay" name="image-overlay"> </slot>
    </image-viewer>
  </div>
</template>
