<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';

export default {
  name: 'ImageWrapper',
  components: {
    NodeViewWrapper,
    GlLoadingIcon,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <node-view-wrapper class="gl-display-inline-block">
    <span class="gl-relative">
      <img
        data-testid="image"
        class="gl-max-w-full gl-h-auto"
        :class="{ 'gl-opacity-5': node.attrs.uploading }"
        :src="node.attrs.src"
      />
      <gl-loading-icon v-if="node.attrs.uploading" class="gl-absolute gl-left-50p gl-top-half" />
    </span>
  </node-view-wrapper>
</template>
