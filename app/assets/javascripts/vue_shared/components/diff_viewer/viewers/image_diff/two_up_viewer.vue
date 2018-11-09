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
  },
};
</script>

<template>
  <div class="two-up view">
    <image-viewer
      :path="oldPath"
      :render-info="true"
      inner-css-classes="frame deleted"
      class="wrap"
    />
    <image-viewer
      :path="newPath"
      :render-info="true"
      :inner-css-classes="['frame', 'added']"
      class="wrap"
    >
      <slot
        slot="image-overlay"
        name="image-overlay"
      >
      </slot>
    </image-viewer>
  </div>
</template>
