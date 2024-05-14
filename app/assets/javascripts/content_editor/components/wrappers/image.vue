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
      this.dragData = {
        handle,
        startX: event.screenX,
        startY: event.screenY,
        width: this.$refs.image.width,
        height: this.$refs.image.height,
      };
    },
    onDrag(event) {
      const { handle, startX, width, height } = this.dragData;
      if (!handle) return;

      const deltaX = event.screenX - startX;
      const newWidth = handle.includes('w') ? width - deltaX : width + deltaX;
      const newHeight = (height / width) * newWidth;

      this.$refs.image.setAttribute('width', newWidth);
      this.$refs.image.setAttribute('height', newHeight);
    },
    onDragEnd() {
      const { handle } = this.dragData;
      if (!handle) return;

      this.dragData = {};

      this.editor
        .chain()
        .focus()
        .updateAttributes(this.node.type, {
          width: this.$refs.image.width,
          height: this.$refs.image.height,
        })
        .setNodeSelection(this.getPos())
        .run();
    },
  },
  resizeHandles: ['ne', 'nw', 'se', 'sw'],
};
</script>
<template>
  <node-view-wrapper
    v-show="!isStaleUploadedImage"
    as="span"
    class="gl-relative gl-display-inline-block"
  >
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
      :src="node.attrs.src"
      :alt="node.attrs.alt"
      :title="node.attrs.title"
      :width="node.attrs.width || 'auto'"
      :height="node.attrs.height || 'auto'"
      :class="{ 'ProseMirror-selectednode': selected }"
    />
  </node-view-wrapper>
</template>
