<script>
import {
  getSandboxFrameSrc,
  BUFFER_IFRAME_HEIGHT,
  SANDBOX_ATTRIBUTES,
} from '../markdown/render_sandboxed_mermaid';

export default {
  name: 'SandboxedMermaid',

  props: {
    source: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      iframeHeight: BUFFER_IFRAME_HEIGHT,
      sandboxFrameSrc: getSandboxFrameSrc(),
    };
  },

  watch: {
    source() {
      this.updateDiagram();
    },
  },

  mounted() {
    window.addEventListener('message', this.onPostMessage, false);
  },

  destroyed() {
    window.removeEventListener('message', this.onPostMessage);
  },

  methods: {
    getSandboxFrameSrc,

    onPostMessage(event) {
      const container = this.$refs.diagramContainer;

      if (event.source === container?.contentWindow) {
        this.iframeHeight = Number(event.data.h) + BUFFER_IFRAME_HEIGHT;
      }
    },

    updateDiagram() {
      const container = this.$refs.diagramContainer;

      // Potential risk associated with '*' discussed in below thread
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74414#note_735183398
      container.contentWindow?.postMessage(this.source, '*');
      container.addEventListener('load', () => {
        container.contentWindow?.postMessage(this.source, '*');
      });
    },
  },

  sandboxFrameSrc: getSandboxFrameSrc(),
  sandboxAttributes: SANDBOX_ATTRIBUTES,
};
</script>
<template>
  <iframe
    ref="diagramContainer"
    :src="$options.sandboxFrameSrc"
    :sandbox="$options.sandboxAttributes"
    frameborder="0"
    scrolling="no"
    width="100%"
    :height="iframeHeight"
  >
  </iframe>
</template>
