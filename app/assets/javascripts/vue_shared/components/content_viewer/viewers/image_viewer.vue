<script>
import { numberToHumanSize } from '../../../../lib/utils/number_utils';

export default {
  props: {
    path: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      width: 0,
      height: 0,
      isZoomable: false,
      isZoomed: false,
    };
  },
  computed: {
    fileSizeReadable() {
      return numberToHumanSize(this.fileSize);
    },
  },
  methods: {
    onImgLoad() {
      const contentImg = this.$refs.contentImg;
      this.isZoomable =
        contentImg.naturalWidth > contentImg.width || contentImg.naturalHeight > contentImg.height;

      this.width = contentImg.naturalWidth;
      this.height = contentImg.naturalHeight;
    },
    onImgClick() {
      if (this.isZoomable) this.isZoomed = !this.isZoomed;
    },
  },
};
</script>

<template>
  <div class="file-container">
    <div class="file-content image_file">
      <img
        ref="contentImg"
        :class="{ 'isZoomable': isZoomable, 'isZoomed': isZoomed }"
        :src="path"
        :alt="path"
        @load="onImgLoad"
        @click="onImgClick"/>
      <p class="file-info prepend-top-10">
        <template v-if="fileSize>0">
          {{ fileSizeReadable }}
        </template>
        <template v-if="fileSize>0 && width && height">
          -
        </template>
        <template v-if="width && height">
          {{ width }} x {{ height }}
        </template>
      </p>
    </div>
  </div>
</template>
