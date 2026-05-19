<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { uploadingStates } from '../../services/upload_helpers';
import mediaResize from './media_resize';

export default {
  name: 'ImageWrapper',
  components: {
    NodeViewWrapper,
  },
  mixins: [mediaResize('image')],
  computed: {
    isStaleUploadedImage() {
      const { uploading } = this.node.attrs;
      return uploading && uploadingStates[uploading];
    },
  },
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
      :draggable="true"
      data-drag-handle
      :src="node.attrs.src"
      :alt="node.attrs.alt"
      :title="node.attrs.title"
      :width="resizeWidth"
      :height="resizeHeight"
      :class="{ 'ProseMirror-selectednode': selected }"
    />
  </node-view-wrapper>
</template>
