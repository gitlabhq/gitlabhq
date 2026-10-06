<script>
import { embedStyle, getIframeClasses, getIframeStyle } from '../markdown/external_content';

export default {
  name: 'EmbeddedIframe',
  props: {
    provider: {
      type: Object,
      required: true,
    },
    src: {
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
    iframeClasses() {
      return getIframeClasses(this.width, this.height);
    },
    iframeStyle() {
      return getIframeStyle(this.width, this.height);
    },
  },
  embedStyle,
};
</script>
<template>
  <div :style="$options.embedStyle">
    <iframe
      :src="src"
      :sandbox="provider.sandbox"
      allowfullscreen="true"
      referrerpolicy="strict-origin-when-cross-origin"
      :width="width"
      :height="height"
      :style="iframeStyle"
      :class="iframeClasses"
    ></iframe>
  </div>
</template>
