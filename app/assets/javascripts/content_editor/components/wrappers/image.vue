<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { uploadingStates } from '../../services/upload_helpers';

export default {
  name: 'ImageWrapper',
  components: {
    NodeViewWrapper,
  },
  props: {
    getPos: {
      type: Function,
      required: true,
    },
    editor: {
      type: Object,
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
    updateAttributes: {
      type: Function,
      required: true,
      default: () => {},
    },
  },
  data() {
    return {
      dragData: {},
    };
  },
  computed: {
    isStaleUploadedImage() {
      const { uploading } = this.node.attrs;
      return uploading && uploadingStates[uploading];
    },
    imageWidth() {
      return this.dragData.width || this.node.attrs.width || 'auto';
    },
    imageHeight() {
      return this.dragData.height || this.node.attrs.height || 'auto';
    },
  },
  mounted() {
    document.addEventListener('mousemove', this.onDrag);
    document.addEventListener('mouseup', this.onDragEnd);
  },
  destroyed() {
    document.removeEventListener('mousemove', this.onDrag);
    document.removeEventListener('mouseup', this.onDragEnd);
  },
  methods: {
    onDragStart(handle, event) {
      const { image } = this.$refs;
      const computedStyle = window.getComputedStyle(image);
      const width = parseInt(image.getAttribute('width'), 10) || parseInt(computedStyle.width, 10);
      const height =
        parseInt(image.getAttribute('height'), 10) || parseInt(computedStyle.height, 10);

      this.dragData = {
        handle,
        startX: event.screenX,
        startY: event.screenY,
        startWidth: width,
        startHeight: height,
        width,
        height,
      };
    },
    onDrag(event) {
      const { handle, startX, startWidth, startHeight } = this.dragData;
      if (!handle) return;

      const deltaX = event.screenX - startX;
      const isLeftHandle = handle.includes('w');
      const newWidth = isLeftHandle ? startWidth - deltaX : startWidth + deltaX;
      const newHeight = Math.floor((startHeight / startWidth) * newWidth);

      this.dragData = {
        ...this.dragData,
        width: Math.max(newWidth, 0),
        height: Math.max(newHeight, 0),
      };
    },
    onDragEnd() {
      const { handle } = this.dragData;
      if (!handle) return;

      const { width, height } = this.dragData;

      this.dragData = {};
      this.updateAttributes({ width, height });
      this.editor.chain().focus().setNodeSelection(this.getPos()).run();
    },
  },
  resizeHandles: ['ne', 'nw', 'se', 'sw'],
};
</script>
<template>
  <node-view-wrapper v-show="!isStaleUploadedImage" as="span" class="gl-relative gl-inline-block">
    <span
      v-for="handle in $options.resizeHandles"
      v-show="selected"
      :key="handle"
      class="image-resize"
      :class="`image-resize-${handle}`"
      :data-testid="`image-resize-${handle}`"
      @mousedown="onDragStart(handle, $event)"
    ></span>
    <img
      ref="image"
      draggable="true"
      data-drag-handle
      :src="node.attrs.src"
      :alt="node.attrs.alt"
      :title="node.attrs.title"
      :width="imageWidth"
      :height="imageHeight"
      :class="{ 'ProseMirror-selectednode': selected }"
    />
  </node-view-wrapper>
</template>
