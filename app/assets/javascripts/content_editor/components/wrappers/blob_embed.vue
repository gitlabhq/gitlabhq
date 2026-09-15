<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { GlIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

const BLOB_ROUTE = /\/-\/blob\//;
const FULL_SHA = /^[0-9a-f]{40}\//;

export default {
  name: 'BlobEmbedWrapper',
  components: {
    NodeViewWrapper,
    GlIcon,
    GlLink,
  },
  props: {
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
  computed: {
    url() {
      return this.node.attrs.url || '';
    },
    label() {
      return this.node.attrs.text || this.filePath;
    },
    filePath() {
      const afterBlob = this.url.split(BLOB_ROUTE)[1];
      if (!afterBlob) return this.url;

      const path = afterBlob.split(/[?#]/)[0].replace(FULL_SHA, '');
      try {
        return decodeURIComponent(path);
      } catch {
        return path;
      }
    },
    range() {
      return this.node.attrs.range;
    },
  },
  methods: {
    s__,
  },
};
</script>
<template>
  <node-view-wrapper as="div" class="gl-my-3">
    <span
      class="gl-inline-flex gl-max-w-full gl-items-center gl-gap-2 gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-bg-subtle gl-px-3 gl-py-2 gl-text-sm"
      :class="{ 'gl-focus': selected }"
    >
      <gl-icon name="doc-code" :size="16" class="gl-shrink-0 gl-text-subtle" />
      <span class="gl-truncate gl-font-monospace">{{ label }}</span>
      <span v-if="range" class="gl-shrink-0 gl-text-subtle">· {{ range }}</span>
      <gl-link
        :href="url"
        target="_blank"
        rel="noopener noreferrer"
        class="gl-inline-flex gl-shrink-0"
        :aria-label="s__('ContentEditor|Open source file')"
        @click.stop
      >
        <gl-icon name="external-link" :size="12" />
      </gl-link>
    </span>
  </node-view-wrapper>
</template>
