<script>
import ImageViewer from '../../../content_viewer/viewers/image_viewer.vue';
import { pixeliseValue } from '../../../lib/utils/dom_utils';

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
  data() {
    return {
      onionMaxWidth: undefined,
      onionMaxHeight: undefined,
      onionOldImgInfo: null,
      onionNewImgInfo: null,
      onionDraggerPos: 0,
      onionOpacity: 1,
      dragging: false,
    };
  },
  computed: {
    onionMaxPixelWidth() {
      return pixeliseValue(this.onionMaxWidth);
    },
    onionMaxPixelHeight() {
      return pixeliseValue(this.onionMaxHeight);
    },
    onionDraggerPixelPos() {
      return pixeliseValue(this.onionDraggerPos);
    },
  },
  beforeDestroy() {
    document.body.removeEventListener('mouseup', this.stopDrag);
    document.body.removeEventListener('touchend', this.stopDrag);
    document.body.removeEventListener('mousemove', this.dragMove);
    document.body.removeEventListener('touchmove', this.dragMove);
  },
  methods: {
    dragMove(e) {
      if (!this.dragging) return;
      const moveX = e.pageX || e.touches[0].pageX;
      const left = moveX - this.$refs.dragTrack.getBoundingClientRect().left;
      const dragTrackWidth =
        this.$refs.dragTrack.clientWidth - this.$refs.dragger.clientWidth || 100;

      let leftValue = left;
      if (leftValue < 0) leftValue = 0;
      if (leftValue > dragTrackWidth) leftValue = dragTrackWidth;

      this.onionOpacity = left / dragTrackWidth;
      this.onionDraggerPos = leftValue;
    },
    startDrag() {
      this.dragging = true;
      document.body.style.userSelect = 'none';
      document.body.addEventListener('mousemove', this.dragMove);
      document.body.addEventListener('touchmove', this.dragMove);
    },
    stopDrag() {
      this.dragging = false;
      document.body.style.userSelect = '';
      document.body.removeEventListener('mousemove', this.dragMove);
      document.body.removeEventListener('touchmove', this.dragMove);
    },
    prepareOnionSkin() {
      if (this.onionOldImgInfo && this.onionNewImgInfo) {
        this.onionMaxWidth = Math.max(
          this.onionOldImgInfo.renderedWidth,
          this.onionNewImgInfo.renderedWidth,
        );
        this.onionMaxHeight = Math.max(
          this.onionOldImgInfo.renderedHeight,
          this.onionNewImgInfo.renderedHeight,
        );

        this.onionOpacity = 1;
        this.onionDraggerPos =
          this.$refs.dragTrack.clientWidth - this.$refs.dragger.clientWidth || 100;

        document.body.addEventListener('mouseup', this.stopDrag);
        document.body.addEventListener('touchend', this.stopDrag);
      }
    },
    onionNewImgLoaded(imgInfo) {
      this.onionNewImgInfo = imgInfo;
      this.prepareOnionSkin();
    },
    onionOldImgLoaded(imgInfo) {
      this.onionOldImgInfo = imgInfo;
      this.prepareOnionSkin();
    },
  },
};
</script>

<template>
  <div class="onion-skin view">
    <div
      :style="{
        width: onionMaxPixelWidth,
        height: onionMaxPixelHeight,
        'user-select': dragging ? 'none' : null,
      }"
      class="onion-skin-frame"
    >
      <div
        :style="{
          width: onionMaxPixelWidth,
          height: onionMaxPixelHeight,
        }"
        class="frame deleted"
      >
        <image-viewer
          key="onionOldImg"
          :render-info="false"
          :path="oldPath"
          @imgLoaded="onionOldImgLoaded"
        />
      </div>
      <div
        ref="addedFrame"
        :style="{
          opacity: onionOpacity,
          width: onionMaxPixelWidth,
          height: onionMaxPixelHeight,
        }"
        class="added frame"
      >
        <image-viewer
          key="onionNewImg"
          :render-info="false"
          :path="newPath"
          @imgLoaded="onionNewImgLoaded"
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
      <div class="controls">
        <div class="transparent"></div>
        <div
          ref="dragTrack"
          class="drag-track"
          @mousedown="startDrag"
          @mouseup="stopDrag"
          @touchstart="startDrag"
          @touchend="stopDrag"
        >
          <div ref="dragger" :style="{ left: onionDraggerPixelPos }" class="dragger"></div>
        </div>
        <div class="opaque"></div>
      </div>
    </div>
  </div>
</template>
