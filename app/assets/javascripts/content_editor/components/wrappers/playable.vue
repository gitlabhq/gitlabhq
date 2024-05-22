<script>
import { GlLink } from '@gitlab/ui';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { uploadingStates } from '../../services/upload_helpers';

export default {
  name: 'PlayableWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    GlLink,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isStaleUploadedMedia() {
      const { uploading } = this.node.attrs;
      return uploading && uploadingStates[uploading];
    },
  },
};
</script>
<template>
  <node-view-wrapper
    v-show="!isStaleUploadedMedia"
    as="span"
    :class="`media-container ${node.type.name}-container`"
  >
    <node-view-content
      :as="node.type.name"
      :src="node.attrs.src"
      controls="true"
      data-setup="{}"
      draggable="true"
      data-drag-handle=""
      :data-title="node.attrs.title || node.attrs.alt"
    />
    <gl-link
      :href="node.attrs.src"
      class="with-attachment-icon"
      target="_blank"
      draggable="true"
      data-drag-handle=""
    >
      {{ node.attrs.title || node.attrs.alt }}
    </gl-link>
  </node-view-wrapper>
</template>
