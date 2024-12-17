<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { throttle } from 'lodash';
import { isLoggedIn } from '~/lib/utils/common_utils';
import DesignImage from './image.vue';
import DesignOverlay from './design_overlay.vue';

const CLICK_DRAG_BUFFER_PX = 2;

export default {
  components: {
    DesignImage,
    DesignOverlay,
    GlLoadingIcon,
  },
  props: {
    image: {
      type: String,
      required: false,
      default: '',
    },
    imageName: {
      type: String,
      required: false,
      default: '',
    },
    discussions: {
      type: Array,
      required: true,
    },
    isAnnotating: {
      type: Boolean,
      required: false,
      default: false,
    },
    scale: {
      type: Number,
      required: false,
      default: 1,
    },
    resolvedDiscussionsExpanded: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    disableCommenting: {
      type: Boolean,
      required: true,
    },
    isSidebarOpen: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      overlayDimensions: null,
      overlayPosition: null,
      currentAnnotationPosition: null,
      zoomFocalPoint: {
        x: 0,
        y: 0,
        width: 0,
        height: 0,
      },
      initialLoad: true,
      lastDragPosition: null,
      isDraggingDesign: false,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    discussionStartingNotes() {
      return this.discussions.map((discussion) => ({
        ...discussion.notes[0],
        index: discussion.index,
      }));
    },
    currentCommentForm() {
      return (this.isAnnotating && this.currentAnnotationPosition) || null;
    },
    presentationStyle() {
      return {
        cursor: this.isDraggingDesign ? 'grabbing' : undefined,
      };
    },
  },
  beforeDestroy() {
    const { presentationViewport } = this.$refs;
    if (!presentationViewport) return;

    presentationViewport.removeEventListener('scroll', this.scrollThrottled, false);
  },
  mounted() {
    const { presentationViewport } = this.$refs;
    if (!presentationViewport) return;

    this.scrollThrottled = throttle(() => {
      this.shiftZoomFocalPoint();
    }, 400);

    presentationViewport.addEventListener('scroll', this.scrollThrottled, false);
  },
  methods: {
    syncCurrentAnnotationPosition() {
      if (!this.currentAnnotationPosition) return;

      const widthRatio = this.overlayDimensions.width / this.currentAnnotationPosition.width;
      const heightRatio = this.overlayDimensions.height / this.currentAnnotationPosition.height;
      const x = this.currentAnnotationPosition.x * widthRatio;
      const y = this.currentAnnotationPosition.y * heightRatio;

      this.currentAnnotationPosition = this.getAnnotationPosition({ x, y });
    },
    setOverlayDimensions(overlayDimensions) {
      this.overlayDimensions = overlayDimensions;

      // every time we set overlay dimensions, we need to
      // update the current annotation as well
      this.syncCurrentAnnotationPosition();
    },
    setOverlayPosition() {
      if (!this.overlayDimensions) {
        this.overlayPosition = {};
      }

      const { presentationViewport } = this.$refs;
      if (!presentationViewport) return;

      // default to center
      this.overlayPosition = {
        left: `calc(50% - ${this.overlayDimensions.width / 2}px)`,
        top: `calc(50% - ${this.overlayDimensions.height / 2}px)`,
      };

      // if the overlay overflows, then don't center
      if (this.overlayDimensions.width > presentationViewport.offsetWidth) {
        this.overlayPosition.left = '0';
      }
      if (this.overlayDimensions.height > presentationViewport.offsetHeight) {
        this.overlayPosition.top = '0';
      }
    },
    /**
     * Return a point that represents the center of an
     * overflowing child element w.r.t it's parent
     */
    getViewportCenter() {
      const { presentationViewport } = this.$refs;
      if (!presentationViewport) return {};

      // get height of scroll bars (i.e. the max values for scrollTop, scrollLeft)
      const scrollBarWidth = presentationViewport.scrollWidth - presentationViewport.offsetWidth;
      const scrollBarHeight = presentationViewport.scrollHeight - presentationViewport.offsetHeight;

      // determine how many child pixels have been scrolled
      const xScrollRatio =
        presentationViewport.scrollLeft > 0 ? presentationViewport.scrollLeft / scrollBarWidth : 0;
      const yScrollRatio =
        presentationViewport.scrollTop > 0 ? presentationViewport.scrollTop / scrollBarHeight : 0;
      const xScrollOffset =
        // eslint-disable-next-line no-implicit-coercion
        (presentationViewport.scrollWidth - presentationViewport.offsetWidth - 0) * xScrollRatio;
      const yScrollOffset =
        // eslint-disable-next-line no-implicit-coercion
        (presentationViewport.scrollHeight - presentationViewport.offsetHeight - 0) * yScrollRatio;

      const viewportCenterX = presentationViewport.offsetWidth / 2;
      const viewportCenterY = presentationViewport.offsetHeight / 2;
      const focalPointX = viewportCenterX + xScrollOffset;
      const focalPointY = viewportCenterY + yScrollOffset;

      return {
        x: focalPointX,
        y: focalPointY,
      };
    },
    /**
     * Scroll the viewport such that the focal point is positioned centrally
     */
    scrollToFocalPoint() {
      const { presentationViewport } = this.$refs;
      if (!presentationViewport) return;

      const scrollX = this.zoomFocalPoint.x - presentationViewport.offsetWidth / 2;
      const scrollY = this.zoomFocalPoint.y - presentationViewport.offsetHeight / 2;

      presentationViewport.scrollTo(scrollX, scrollY);
    },
    scaleZoomFocalPoint() {
      const { x, y, width, height } = this.zoomFocalPoint;
      const widthRatio = this.overlayDimensions.width / width;
      const heightRatio = this.overlayDimensions.height / height;

      this.zoomFocalPoint = {
        x: Math.round(x * widthRatio * 100) / 100,
        y: Math.round(y * heightRatio * 100) / 100,
        ...this.overlayDimensions,
      };
    },
    shiftZoomFocalPoint() {
      this.zoomFocalPoint = {
        ...this.getViewportCenter(),
        ...this.overlayDimensions,
      };
    },
    onImageResize(imageDimensions) {
      this.setOverlayDimensions(imageDimensions);
      this.setOverlayPosition();

      this.$nextTick(() => {
        if (this.initialLoad) {
          // set focal point on initial load
          this.shiftZoomFocalPoint();
          this.initialLoad = false;
        } else {
          this.scaleZoomFocalPoint();
          this.scrollToFocalPoint();
        }
      });
    },
    getAnnotationPosition(coordinates) {
      const { x, y } = coordinates;
      const { width, height } = this.overlayDimensions;
      return {
        x: Math.round(x),
        y: Math.round(y),
        width: Math.round(width),
        height: Math.round(height),
      };
    },
    openCommentForm(coordinates) {
      this.currentAnnotationPosition = this.getAnnotationPosition(coordinates);
      this.$emit('openCommentForm', this.currentAnnotationPosition);
    },
    closeCommentForm() {
      this.currentAnnotationPosition = null;
      this.$emit('closeCommentForm');
    },
    moveNote({ noteId, discussionId, coordinates }) {
      const position = this.getAnnotationPosition(coordinates);
      this.$emit('moveNote', { noteId, discussionId, position });
    },
    onPresentationMousedown({ clientX, clientY }) {
      if (!this.isDesignOverflowing()) return;

      this.lastDragPosition = {
        x: clientX,
        y: clientY,
      };
    },
    getDragDelta(clientX, clientY) {
      return {
        deltaX: this.lastDragPosition.x - clientX,
        deltaY: this.lastDragPosition.y - clientY,
      };
    },
    exceedsDragThreshold(clientX, clientY) {
      const { deltaX, deltaY } = this.getDragDelta(clientX, clientY);

      return Math.abs(deltaX) > CLICK_DRAG_BUFFER_PX || Math.abs(deltaY) > CLICK_DRAG_BUFFER_PX;
    },
    shouldDragDesign(clientX, clientY) {
      return (
        this.lastDragPosition &&
        (this.isDraggingDesign || this.exceedsDragThreshold(clientX, clientY))
      );
    },
    onPresentationMousemove({ clientX, clientY }) {
      const { presentationViewport } = this.$refs;
      if (!presentationViewport || !this.shouldDragDesign(clientX, clientY)) return;

      this.isDraggingDesign = true;

      const { scrollLeft, scrollTop } = presentationViewport;
      const { deltaX, deltaY } = this.getDragDelta(clientX, clientY);
      presentationViewport.scrollTo(scrollLeft + deltaX, scrollTop + deltaY);

      this.lastDragPosition = {
        x: clientX,
        y: clientY,
      };
    },
    onPresentationMouseup() {
      this.lastDragPosition = null;
      this.isDraggingDesign = false;
    },
    isDesignOverflowing() {
      const { presentationViewport } = this.$refs;
      if (!presentationViewport) return false;

      return (
        presentationViewport.scrollWidth > presentationViewport.offsetWidth ||
        presentationViewport.scrollHeight > presentationViewport.offsetHeight
      );
    },
  },
};
</script>

<template>
  <div
    ref="presentationViewport"
    data-testid="presentation-viewport"
    class="overflow-auto gl-relative gl-h-full gl-w-full gl-p-5"
    :style="presentationStyle"
    @mousedown="onPresentationMousedown"
    @mousemove="onPresentationMousemove"
    @mouseup="onPresentationMouseup"
    @mouseleave="onPresentationMouseup"
    @touchstart="onPresentationMousedown"
    @touchmove="onPresentationMousemove"
    @touchend="onPresentationMouseup"
    @touchcancel="onPresentationMouseup"
  >
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-flex gl-h-full gl-items-center" />
    <div v-else class="gl-relative gl-flex gl-h-full gl-w-full gl-items-center">
      <design-image
        v-if="image"
        :image="image"
        :name="imageName"
        :scale="scale"
        @resize="onImageResize"
      />
      <design-overlay
        v-if="overlayDimensions && overlayPosition"
        :dimensions="overlayDimensions"
        :position="overlayPosition"
        :notes="discussionStartingNotes"
        :current-comment-form="currentCommentForm"
        :disable-commenting="!isLoggedIn || isDraggingDesign || disableCommenting"
        :disable-notes="!isSidebarOpen"
        :resolved-discussions-expanded="resolvedDiscussionsExpanded"
        @openCommentForm="openCommentForm"
        @closeCommentForm="closeCommentForm"
        @moveNote="moveNote"
      />
    </div>
  </div>
</template>
