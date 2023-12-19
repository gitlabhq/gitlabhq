<script>
import { throttle } from 'lodash';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { encodeSaferUrl } from '~/lib/utils/url_utility';

const BLOB_PREFIX = 'blob:';

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
      required: false,
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
      renderedWidth: 0,
      renderedHeight: 0,
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
    safePath() {
      return this.path.startsWith(BLOB_PREFIX) ? this.path : encodeSaferUrl(this.path);
    },
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  mounted() {
    // The onImgLoad may have happened before the control was actually mounted
    this.onImgLoad();
    this.resizeThrottled = throttle(this.onImgLoad, 400);
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
          this.renderedWidth = contentImg.clientWidth;
          this.renderedHeight = contentImg.clientHeight;

          this.$emit('imgLoaded', {
            width: this.width,
            height: this.height,
            renderedWidth: this.renderedWidth,
            renderedHeight: this.renderedHeight,
          });
        });
      }
    },
  },
};
</script>

<template>
  <div data-testid="image-viewer">
    <div :class="innerCssClasses" class="position-relative">
      <img ref="contentImg" :src="safePath" @load="onImgLoad" />
      <slot
        name="image-overlay"
        :rendered-width="renderedWidth"
        :rendered-height="renderedHeight"
      ></slot>
    </div>
    <p v-if="renderInfo" class="image-info">
      <template v-if="hasFileSize">
        {{ fileSizeReadable }}
      </template>
      <template v-if="hasFileSize && hasDimensions"> | </template>
      <template v-if="hasDimensions">
        <strong>{{ s__('ImageViewerDimensions|W') }}</strong
        >: {{ width }} | <strong>{{ s__('ImageViewerDimensions|H') }}</strong
        >: {{ height }}
      </template>
    </p>
  </div>
</template>
