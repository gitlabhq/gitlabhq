<script>
export default {
  props: {
    observabilityIframeSrc: {
      type: String,
      required: true,
    },
  },
  mounted() {
    window.addEventListener('message', this.messageHandler);
  },
  methods: {
    messageHandler(e) {
      const isExpectedOrigin = e.origin === new URL(this.observabilityIframeSrc)?.origin;

      const isNewObservabilityPath = this.$route?.query?.observability_path !== e.data?.url;

      const shouldNotHandleMessage = !isExpectedOrigin || !e.data.url || !isNewObservabilityPath;

      if (shouldNotHandleMessage) {
        return;
      }

      // this will update the `observability_path` query param on each route change inside Observability UI
      this.$router.replace({
        name: this.$route.pathname,
        query: { ...this.$route.query, observability_path: e.data.url },
      });
    },
  },
};
</script>

<template>
  <iframe
    id="observability-ui-iframe"
    data-testid="observability-ui-iframe"
    frameborder="0"
    height="100%"
    :src="observabilityIframeSrc"
  ></iframe>
</template>
