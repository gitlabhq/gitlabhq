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
    <gl-link
      :href="node.attrs.src"
      target="_blank"
      :draggable="true"
      data-drag-handle=""
      class="with-attachment-icon gl-mb-1 gl-text-sm gl-text-subtle"
    >
      {{ node.attrs.title || node.attrs.alt }}
    </gl-link>
    <node-view-content
      :class="{ 'gl-rounded-lg': node.type.name == 'video' }"
      :as="node.type.name"
      :src="node.attrs.src"
      controls="true"
      data-setup="{}"
      :draggable="true"
      data-drag-handle=""
      :data-title="node.attrs.title || node.attrs.alt"
    />
  </node-view-wrapper>
</template>
