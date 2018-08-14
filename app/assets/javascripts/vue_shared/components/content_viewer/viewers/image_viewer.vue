<script>
import _ from 'underscore';
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
    renderInfo: {
      type: Boolean,
      default: true,
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
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  mounted() {
    // The onImgLoad may have happened before the control was actually mounted
    this.onImgLoad();
    this.resizeThrottled = _.throttle(this.onImgLoad, 400);
    window.addEventListener('resize', this.resizeThrottled, false);
  },
  methods: {
    onImgLoad() {
      requestIdleCallback(this.calculateImgSize, { timeout: 1000 });
    },
    calculateImgSize() {
      const { contentImg } = this.$refs;

      if (contentImg) {
        this.isZoomable =
          contentImg.naturalWidth > contentImg.width ||
          contentImg.naturalHeight > contentImg.height;

        this.width = contentImg.naturalWidth;
        this.height = contentImg.naturalHeight;

        this.$emit('imgLoaded', {
          width: this.width,
          height: this.height,
          renderedWidth: contentImg.clientWidth,
          renderedHeight: contentImg.clientHeight,
        });
      }
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
        :class="{ 'is-zoomable': isZoomable, 'is-zoomed': isZoomed }"
        :src="path"
        :alt="path"
        @load="onImgLoad"
        @click="onImgClick"/>
      <p
        v-if="renderInfo"
        class="file-info prepend-top-10">
        <template v-if="fileSize>0">
          {{ fileSizeReadable }}
        </template>
        <template v-if="fileSize>0 && width && height">
          |
        </template>
        <template v-if="width && height">
          W: {{ width }} | H: {{ height }}
        </template>
      </p>
    </div>
  </div>
</template>
