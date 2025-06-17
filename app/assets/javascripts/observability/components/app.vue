<script>
export default {
  props: {
    o11yUrl: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },

  computed: {
    iframeUrl() {
      const urlWithPath = new URL(this.path, this.o11yUrl);
      return urlWithPath.toString();
    },
  },
};
</script>

<template>
  <div
    class="gl-h-full gl-grow gl-overflow-hidden gl-rounded-base gl-border-1 gl-border-solid gl-border-default"
  >
    <iframe
      ref="signozFrame"
      :src="iframeUrl"
      frameborder="0"
      class="gl-h-full gl-w-full"
      :title="s__('Observability|Observability Dashboard')"
      sandbox="allow-same-origin allow-scripts allow-forms"
    ></iframe>
  </div>
</template>
