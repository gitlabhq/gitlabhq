<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import simplePoll from '~/lib/utils/simple_poll';
import { createMessageValidator } from '../utils/message_validator';
import {
  MESSAGE_TYPES,
  TIMEOUTS,
  MAX_POLLING_ATTEMPTS,
  POLLING_TIMEOUT,
  PROVISIONING_MESSAGE_INTERVAL,
} from '../constants';
import { buildIframeUrl, extractTargetPath } from '../utils/url_helpers';
import { AuthManager } from '../utils/auth_manager';
import ObservabilityLoading from './observability_loading.vue';

export default {
  name: 'ObservabilityApp',
  components: {
    GlAlert,
    ObservabilityLoading,
  },
  i18n: {
    provisioningMessages: [
      s__('Observability|Configuring authentication'),
      s__('Observability|Allocating compute resources'),
      s__('Observability|Spinning up service containers'),
      s__('Observability|Provisioning databases'),
      s__('Observability|Configuring OpenTelemetry collectors'),
    ],
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
        // Allow empty objects - polling will handle fetching tokens
        if (!authTokens || Object.keys(authTokens).length === 0) {
          return true;
        }

        const requiredProperties = ['accessJwt', 'refreshJwt'];
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
    pollingEndpoint: {
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
      currentAuthTokens: this.authTokens || {},
      pollingCancelled: false,
      pollingAttempts: 0,
      authTokensStatus: null,
      provisioningTimedOut: false,
      currentProvisioningMessageIndex: 0,
      provisioningMessageInterval: null,
    };
  },

  computed: {
    iframeUrl() {
      return buildIframeUrl(this.path, this.o11yUrl);
    },

    targetPath() {
      return extractTargetPath(this.path, this.o11yUrl);
    },

    needsPolling() {
      const { accessJwt, refreshJwt } = this.currentAuthTokens || {};
      return !accessJwt?.trim() || !refreshJwt?.trim();
    },

    isProvisioning() {
      return this.provisioningTimedOut && this.authTokensStatus === 'provisioning';
    },

    showProvisioningMessage() {
      return this.isLoading && this.authTokensStatus === 'provisioning';
    },

    currentProvisioningMessage() {
      return this.$options.i18n.provisioningMessages[this.currentProvisioningMessageIndex];
    },

    authAlert() {
      return this.isProvisioning
        ? {
            variant: 'warning',
            message: s__(
              'Observability|The observability service is still initializing. Please try again in a few minutes.',
            ),
          }
        : {
            variant: 'danger',
            message: s__('Observability|Authentication failed. Please refresh the page.'),
          };
    },
  },

  watch: {
    showProvisioningMessage(newValue) {
      if (newValue) {
        this.startProvisioningMessageCycle();
      } else {
        this.stopProvisioningMessageCycle();
      }
    },
  },

  created() {
    this.handleMessage = this.handleMessage.bind(this);
  },

  mounted() {
    if (this.needsPolling) {
      this.startPolling();
    } else {
      this.initializeAuth();
    }
  },

  beforeUnmount() {
    this.pollingCancelled = true;
    clearTimeout(this.iframeReadyTimeout);
    this.stopProvisioningMessageCycle();
    if (this.authManager) {
      this.authManager.destroy();
    }
    window.removeEventListener('message', this.handleMessage);
  },

  methods: {
    handleIframeLoad() {
      const iframe = this.$refs.o11yFrame;
      this.iframeReadyTimeout = setTimeout(() => {
        if (!this.authManager) return;
        this.authManager.sendAuthMessage(iframe, true);
      }, TIMEOUTS.IFRAME_READY_DELAY);
    },

    initializeAuth() {
      if (this.authManager) {
        return;
      }

      this.allowedOrigin = new URL(this.o11yUrl).origin;
      this.messageValidator = createMessageValidator(this.allowedOrigin);
      this.authManager = new AuthManager(
        this.allowedOrigin,
        this.currentAuthTokens,
        this.targetPath,
      );
      this.authManager.setCallbacks(this.handleAuthSuccess, this.handleAuthError);

      window.addEventListener('message', this.handleMessage);
    },

    startPolling() {
      this.isLoading = true;
      this.pollingAttempts = 0;

      simplePoll(
        (continuePolling, stopPolling) => {
          this.pollForTokens(continuePolling, stopPolling);
        },
        // We rely on MAX_POLLING_ATTEMPTS to stop polling, but set a timeout as a safeguard
        { timeout: POLLING_TIMEOUT },
      )
        .then((tokens) => {
          if (this.pollingCancelled) return;
          this.currentAuthTokens = tokens;
          this.isLoading = false;
          this.initializeAuth();
        })
        .catch(() => {
          if (this.pollingCancelled) return;
          this.isLoading = false;
          this.isAuthenticated = false;
        });
    },

    pollForTokens(continuePolling, stopPolling) {
      if (this.pollingCancelled) {
        stopPolling(new Error('CANCELLED'));
        return;
      }

      this.pollingAttempts += 1;
      if (this.pollingAttempts > MAX_POLLING_ATTEMPTS) {
        this.provisioningTimedOut = true;
        stopPolling(new Error('MAX_ATTEMPTS'));
        return;
      }

      axios
        .get(this.pollingEndpoint)
        .then(({ data }) => {
          if (this.pollingCancelled) {
            stopPolling(new Error('CANCELLED'));
            return;
          }

          if (data.auth_tokens?.status) {
            this.authTokensStatus = data.auth_tokens.status;
          }

          const tokens = this.transformTokens(data.auth_tokens);
          if (tokens.accessJwt && tokens.refreshJwt) {
            stopPolling(tokens);
          } else {
            continuePolling();
          }
        })
        .catch((error) => {
          if (this.pollingCancelled) {
            stopPolling(new Error('CANCELLED'));
            return;
          }

          const status = error?.response?.status;
          const isTerminalClientError =
            typeof status === 'number' && status >= 400 && status < 500 && status !== 429;

          if (isTerminalClientError) {
            stopPolling(new Error('CLIENT_ERROR'));
          } else {
            continuePolling();
          }
        });
    },

    transformTokens(authTokens) {
      if (!authTokens) return {};
      const transformed = {};
      if (authTokens.access_jwt) {
        transformed.accessJwt = authTokens.access_jwt;
      }
      if (authTokens.refresh_jwt) {
        transformed.refreshJwt = authTokens.refresh_jwt;
      }
      return transformed;
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

    startProvisioningMessageCycle() {
      this.stopProvisioningMessageCycle();
      this.currentProvisioningMessageIndex = 0;

      this.provisioningMessageInterval = setInterval(() => {
        this.currentProvisioningMessageIndex =
          (this.currentProvisioningMessageIndex + 1) %
          this.$options.i18n.provisioningMessages.length;
      }, PROVISIONING_MESSAGE_INTERVAL);
    },

    stopProvisioningMessageCycle() {
      if (this.provisioningMessageInterval) {
        clearInterval(this.provisioningMessageInterval);
        this.provisioningMessageInterval = null;
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-h-full gl-grow gl-overflow-hidden gl-rounded-base gl-border-1 gl-border-solid gl-border-default"
  >
    <div
      v-if="isLoading"
      class="gl-mb-0 gl-mt-0 gl-flex gl-h-full gl-flex-col gl-items-center gl-justify-center gl-text-size-h-display gl-font-semibold gl-leading-36"
    >
      <observability-loading data-testid="o11y-loading-status" />
      <div
        class="o11y-status gl-mx-auto gl-mb-2 gl-mt-4 gl-max-w-lg gl-text-center"
        :class="{ 'gl-invisible': !showProvisioningMessage }"
      >
        <p class="gl-mb-0 gl-mt-4">
          <span class="gl-text-size-h-display gl-font-semibold gl-leading-36">
            {{ s__('Observability|Initializing your Observability service') }} </span
          ><br />
          <span class="gl-text-md gl-text-subtle">
            {{ currentProvisioningMessage }}
          </span>
        </p>
      </div>
    </div>
    <gl-alert
      v-else-if="!isAuthenticated"
      :variant="authAlert.variant"
      :dismissible="false"
      class="gl-m-5"
      data-testid="o11y-error-status"
    >
      {{ authAlert.message }}
    </gl-alert>
    <iframe
      v-if="authManager"
      v-show="isAuthenticated"
      ref="o11yFrame"
      frameborder="0"
      sandbox="allow-same-origin allow-scripts allow-forms allow-downloads allow-popups"
      class="gl-h-full gl-w-full"
      :src="iframeUrl"
      :title="title"
      @load="handleIframeLoad"
    ></iframe>
  </div>
</template>
