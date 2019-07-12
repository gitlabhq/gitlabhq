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
    innerCssClasses: {
      type: [Array, Object, String],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      width: 0,
      height: 0,
      isLoaded: false,
    };
  },
  computed: {
    fileSizeReadable() {
      return numberToHumanSize(this.fileSize);
    },

    hasFileSize() {
      return this.fileSize > 0;
    },
    hasDimensions() {
      return this.width && this.height;
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
        this.width = contentImg.naturalWidth;
        this.height = contentImg.naturalHeight;

        this.$nextTick(() => {
          this.isLoaded = true;

          this.$emit('imgLoaded', {
            width: this.width,
            height: this.height,
            renderedWidth: contentImg.clientWidth,
            renderedHeight: contentImg.clientHeight,
          });
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <div :class="innerCssClasses" class="position-relative">
      <img ref="contentImg" :src="path" @load="onImgLoad" /> <slot name="image-overlay"></slot>
    </div>
    <p v-if="renderInfo" class="image-info">
      <template v-if="hasFileSize">
        {{ fileSizeReadable }}
      </template>
      <template v-if="hasFileSize && hasDimensions">
        |
      </template>
      <template v-if="hasDimensions">
        <strong>{{ s__('ImageViewerDimensions|W') }}</strong
        >: {{ width }} | <strong>{{ s__('ImageViewerDimensions|H') }}</strong
        >: {{ height }}
      </template>
    </p>
  </div>
</template>
