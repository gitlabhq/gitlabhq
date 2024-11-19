<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import { throttle } from 'lodash';
import { DESIGN_MARK_APP_START, DESIGN_MAIN_IMAGE_OUTPUT } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';

export default {
  components: {
    GlIcon,
  },
  props: {
    image: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    scale: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  data() {
    return {
      baseImageSize: null,
      imageStyle: null,
      imageError: false,
    };
  },
  watch: {
    scale(val) {
      this.zoom(val);
    },
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  mounted() {
    if (!this.image) {
      this.onImgLoad();
    }

    this.resizeThrottled = throttle(() => {
      // NOTE: if imageStyle is set, then baseImageSize
      // won't change due to resize. We must still emit a
      // `resize` event so that the parent can handle
      // resizes appropriately (e.g. for design_overlay)
      this.setBaseImageSize();
    }, 400);
    window.addEventListener('resize', this.resizeThrottled, false);
  },
  methods: {
    onImgLoad() {
      requestIdleCallback(this.setBaseImageSize, { timeout: 1000 });
      requestIdleCallback(this.setImageNaturalScale, { timeout: 1000 });
      performanceMarkAndMeasure({
        measures: [
          {
            name: DESIGN_MAIN_IMAGE_OUTPUT,
            start: DESIGN_MARK_APP_START,
          },
        ],
      });
    },
    onImgError() {
      this.imageError = true;
    },
    setBaseImageSize() {
      const { contentImg } = this.$refs;
      if (!contentImg) return;
      if (contentImg.offsetHeight === 0 || contentImg.offsetWidth === 0) {
        this.baseImageSize = {
          height: contentImg.naturalHeight,
          width: contentImg.naturalWidth,
        };
      } else {
        this.baseImageSize = {
          height: contentImg.offsetHeight,
          width: contentImg.offsetWidth,
        };
      }

      this.onResize({ width: this.baseImageSize.width, height: this.baseImageSize.height });
    },
    setImageNaturalScale() {
      const { contentImg } = this.$refs;

      if (!contentImg) {
        return;
      }

      const { naturalHeight, naturalWidth } = contentImg;

      // In case image 404s
      if (naturalHeight === 0 || naturalWidth === 0) {
        return;
      }

      const { height, width } = this.baseImageSize;

      this.imageStyle = {
        width: `${width}px`,
        height: `${height}px`,
      };

      this.$parent.$emit(
        'setMaxScale',
        Math.round(((height + width) / (naturalHeight + naturalWidth)) * 100) / 100,
      );
    },
    onResize({ width, height }) {
      this.$emit('resize', { width, height });
    },
    zoom(amount) {
      if (amount === 1) {
        this.imageStyle = null;
        this.$nextTick(() => {
          this.setBaseImageSize();
        });
        return;
      }
      const width = this.baseImageSize.width * amount;
      const height = this.baseImageSize.height * amount;

      this.imageStyle = {
        width: `${width}px`,
        height: `${height}px`,
      };

      this.onResize({ width, height });
    },
  },
};
</script>

<template>
  <div class="js-design-image gl-mx-auto gl-my-auto">
    <gl-icon v-if="imageError" name="media-broken" :size="48" variant="disabled" />
    <img
      v-show="!imageError"
      ref="contentImg"
      class="gl-border gl-max-h-full"
      :src="image"
      :alt="name"
      :style="imageStyle"
      :class="{ 'img-fluid': !imageStyle }"
      @error="onImgError"
      @load="onImgLoad"
    />
  </div>
</template>
