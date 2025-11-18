<script>
import { createMessageValidator } from '../utils/message_validator';
import { MESSAGE_TYPES, TIMEOUTS } from '../constants';
import { buildIframeUrl, extractTargetPath } from '../utils/url_helpers';
import { AuthManager } from '../utils/auth_manager';
import ObservabilityLoading from './observability_loading.vue';

export default {
  name: 'ObservabilityApp',
  components: {
    ObservabilityLoading,
  },
  props: {
    o11yUrl: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    authTokens: {
      type: Object,
      required: true,
      validator(authTokens) {
        const requiredProperties = ['userId', 'accessJwt', 'refreshJwt'];

        return requiredProperties.every((prop) => {
          const value = authTokens[prop];
          return value && typeof value === 'string' && value.trim().length > 0;
        });
      },
    },
    title: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      allowedOrigin: null,
      messageValidator: null,
      authManager: null,
      isLoading: true,
      isAuthenticated: false,
    };
  },

  computed: {
    iframeUrl() {
      return buildIframeUrl(this.path, this.o11yUrl);
    },

    targetPath() {
      return extractTargetPath(this.path, this.o11yUrl);
    },
  },

  mounted() {
    this.allowedOrigin = new URL(this.o11yUrl).origin;
    this.messageValidator = createMessageValidator(this.allowedOrigin);
    this.authManager = new AuthManager(this.allowedOrigin, this.authTokens, this.targetPath);
    this.authManager.setCallbacks(
      this.handleAuthSuccess.bind(this),
      this.handleAuthError.bind(this),
    );
    this.setupIframeHandlers();
  },

  beforeUnmount() {
    if (this.authManager) {
      this.authManager.destroy();
    }
    window.removeEventListener('message', this.handleMessage);
  },

  methods: {
    setupIframeHandlers() {
      const iframe = this.$refs.o11yFrame;

      iframe.addEventListener('load', () => {
        setTimeout(() => {
          this.authManager.sendAuthMessage(iframe, true);
        }, TIMEOUTS.IFRAME_READY_DELAY);
      });

      this.handleMessage = this.handleMessage.bind(this);
      window.addEventListener('message', this.handleMessage);
    },

    handleAuthSuccess() {
      this.isLoading = false;
      this.isAuthenticated = true;
    },

    handleAuthError() {
      this.isLoading = false;
      this.isAuthenticated = false;
    },

    handleMessage(event) {
      const validation = this.messageValidator.validateMessage(
        event,
        this.authManager.getMessageNonce(),
        this.authManager.getExpectedResponseCounter(),
      );

      if (!validation.valid) {
        return;
      }

      this.handleValidMessage(event.data);
    },

    handleValidMessage(data) {
      if (data.type === MESSAGE_TYPES.AUTH_STATUS) {
        if (data.authenticated) {
          this.authManager.handleAuthSuccess();
        } else {
          this.authManager.handleAuthenticationError();
        }
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-h-full gl-grow gl-overflow-hidden gl-rounded-base gl-border-1 gl-border-solid gl-border-default"
  >
    <observability-loading v-if="isLoading" data-testid="o11y-loading-status" />
    <div v-else-if="!isAuthenticated" class="o11y-status" data-testid="o11y-error-status">
      {{ s__('Observability|Authentication failed. Please refresh the page.') }}
    </div>
    <iframe
      v-show="isAuthenticated"
      ref="o11yFrame"
      frameborder="0"
      sandbox="allow-same-origin allow-scripts allow-forms allow-downloads allow-popups"
      class="gl-h-full gl-w-full"
      :src="iframeUrl"
      :title="title"
    ></iframe>
  </div>
</template>
