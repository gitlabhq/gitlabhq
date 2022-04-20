<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';

const tagNameMap = {
  image: 'img',
  video: 'video',
  audio: 'audio',
};

export default {
  name: 'MediaWrapper',
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
  computed: {
    tagName() {
      return tagNameMap[this.node.type.name] || 'img';
    },
  },
};
</script>
<template>
  <node-view-wrapper class="gl-display-inline-block">
    <span class="gl-relative" :class="{ [`media-container ${tagName}-container`]: true }">
      <gl-loading-icon v-if="node.attrs.uploading" class="gl-absolute gl-left-50p gl-top-half" />
      <component
        :is="tagName"
        data-testid="media"
        :class="{
          'gl-max-w-full gl-h-auto': tagName !== 'audio',
          'gl-opacity-5': node.attrs.uploading,
        }"
        :title="node.attrs.title || node.attrs.alt"
        :alt="node.attrs.alt"
        :src="node.attrs.src"
        controls="true"
      />
      <a v-if="tagName !== 'img'" :href="node.attrs.canonicalSrc || node.attrs.src" @click.prevent>
        {{ node.attrs.title || node.attrs.alt }}
      </a>
    </span>
  </node-view-wrapper>
</template>
