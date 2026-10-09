<script>
import { embedDimensions, getIframeStyle } from '../markdown/external_content';
import ExternalContent from './external_content.vue';

export default {
  name: 'EmbeddedIframe',
  components: {
    ExternalContent,
  },
  props: {
    provider: {
      type: Object,
      required: true,
    },
    src: {
      type: String,
      required: true,
    },
    canonicalSrc: {
      type: String,
      required: true,
    },
    width: {
      type: String,
      required: false,
      default: null,
    },
    height: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    dimensions() {
      return embedDimensions(this.width, this.height);
    },
    iframeStyle() {
      return getIframeStyle(this.dimensions.width, this.dimensions.height);
    },
  },
  methods: {
    focusIframe() {
      this.$refs.iframe.focus();
    },
  },
};
</script>
<template>
  <external-content
    #default="{ title }"
    :provider="provider"
    :href="canonicalSrc"
    :width="dimensions.width"
    :height="dimensions.height"
    data-gfm-ignore
    @activated="focusIframe"
  >
    <iframe
      ref="iframe"
      :src="src"
      :title="title"
      :sandbox="provider.sandbox"
      allowfullscreen="true"
      referrerpolicy="strict-origin-when-cross-origin"
      :width="dimensions.width"
      :height="dimensions.height"
      :style="iframeStyle"
      class="gl-min-w-full gl-border-none"
    ></iframe>
  </external-content>
</template>
