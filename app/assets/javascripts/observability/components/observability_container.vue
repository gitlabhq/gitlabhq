<script>
import { buildClient } from '../client';
import { SKELETON_SPINNER_VARIANT } from '../constants';
import ObservabilitySkeleton from './skeleton/index.vue';

export default {
  SKELETON_SPINNER_VARIANT,
  components: {
    ObservabilitySkeleton,
  },
  props: {
    oauthUrl: {
      type: String,
      required: true,
    },
    tracingUrl: {
      type: String,
      required: true,
    },
    provisioningUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      observabilityClient: null,
      authCompleted: false,
    };
  },
  mounted() {
    window.addEventListener('message', this.messageHandler);

    // TODO: Improve local GDK dev experience with tracing https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2308
    // Uncomment the lines below to to test this locally
    // setTimeout(() => {
    //   this.messageHandler({
    //     data: { type: 'AUTH_COMPLETION', status: 'success' },
    //     origin: new URL(this.oauthUrl).origin,
    //   });
    // }, 2000);
  },
  destroyed() {
    window.removeEventListener('message', this.messageHandler);
  },
  methods: {
    messageHandler(e) {
      const isExpectedOrigin = e.origin === new URL(this.oauthUrl).origin;
      if (!isExpectedOrigin) return;

      const { data } = e;

      if (data.type === 'AUTH_COMPLETION') {
        if (this.authCompleted) return;

        const { status, message, statusCode } = data;
        if (status === 'success') {
          this.observabilityClient = buildClient({
            provisioningUrl: this.provisioningUrl,
            tracingUrl: this.tracingUrl,
          });
          this.$refs.observabilitySkeleton?.onContentLoaded();
        } else if (status === 'error') {
          // eslint-disable-next-line @gitlab/require-i18n-strings,no-console
          console.error('GOB auth failed with error:', message, statusCode);
          this.$refs.observabilitySkeleton?.onError();
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
      :src="oauthUrl"
      data-testid="observability-oauth-iframe"
    ></iframe>

    <observability-skeleton
      ref="observabilitySkeleton"
      :variant="$options.SKELETON_SPINNER_VARIANT"
    >
      <slot v-if="observabilityClient" :observability-client="observabilityClient"></slot>
    </observability-skeleton>
  </div>
</template>
