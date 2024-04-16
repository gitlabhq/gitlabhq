<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { logError } from '~/lib/logger';
import { buildClient } from '../client';
import ObservabilityLoader from './loader/index.vue';
import { CONTENT_STATE } from './loader/constants';

export default {
  components: {
    ObservabilityLoader,
  },
  props: {
    apiConfig: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      observabilityClient: null,
      authCompleted: false,
      loaderContentState: null,
    };
  },
  mounted() {
    window.addEventListener('message', this.messageHandler);

    // TODO: Improve local GDK dev experience with tracing https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2308
    // Uncomment the lines below to to test this locally
    // setTimeout(() => {
    //   this.messageHandler({
    //     data: { type: 'AUTH_COMPLETION', status: 'success' },
    //     origin: new URL(this.apiConfig.oauthUrl).origin,
    //   });
    // }, 2000);
  },
  destroyed() {
    window.removeEventListener('message', this.messageHandler);
  },
  methods: {
    messageHandler(e) {
      const isExpectedOrigin = e.origin === new URL(this.apiConfig.oauthUrl).origin;
      if (!isExpectedOrigin) return;

      const { data } = e;

      if (data.type === 'AUTH_COMPLETION') {
        if (this.authCompleted) return;

        const { status, message, statusCode } = data;
        if (status === 'success') {
          this.observabilityClient = buildClient(this.apiConfig);
          this.$emit('observability-client-ready', this.observabilityClient);
          this.loaderContentState = CONTENT_STATE.LOADED;
        } else if (status === 'error') {
          const error = new Error(`GOB auth failed with error: ${message} - status: ${statusCode}`);
          Sentry.captureException(error);
          logError(error);
          this.loaderContentState = CONTENT_STATE.ERROR;
        }
        this.authCompleted = true;
      }
    },
  },
};
</script>

<template>
  <div>
    <iframe
      v-if="!authCompleted"
      sandbox="allow-same-origin allow-forms allow-scripts"
      hidden
      :src="apiConfig.oauthUrl"
      data-testid="observability-oauth-iframe"
    ></iframe>

    <observability-loader :content-state="loaderContentState">
      <slot v-if="observabilityClient" :observability-client="observabilityClient"></slot>
    </observability-loader>
  </div>
</template>
