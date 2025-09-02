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
    encodePath: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="two-up view gl-flex">
    <image-viewer
      :path="oldPath"
      :file-size="oldSize"
      :render-info="true"
      inner-css-classes="frame deleted"
      :encode-path="encodePath"
      class="wrap !gl-w-1/2"
    />
    <image-viewer
      :path="newPath"
      :file-size="newSize"
      :render-info="true"
      :inner-css-classes="['frame', 'added']"
      :encode-path="encodePath"
      class="wrap !gl-w-1/2"
    >
      <template #image-overlay="{ renderedWidth, renderedHeight }">
        <slot
          :rendered-width="renderedWidth"
          :rendered-height="renderedHeight"
          name="image-overlay"
        ></slot>
      </template>
    </image-viewer>
  </div>
</template>
