<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import simplePoll from '~/lib/utils/simple_poll';
import { createMessageValidator } from '../utils/message_validator';
import {
  MESSAGE_TYPES,
  TIMEOUTS,
  MAX_POLLING_ATTEMPTS,
  POLLING_TIMEOUT,
  MAX_BFF_SESSION_ATTEMPTS,
  BFF_SESSION_TIMEOUT,
  PROVISIONING_MESSAGE_INTERVAL,
} from '../constants';
import { buildIframeUrl } from '../utils/url_helpers';
import { AuthManager } from '../utils/auth_manager';
import iframeNavigator from '../iframe_navigator';
import ObservabilityLoading from './observability_loading.vue';

export default {
  name: 'ObservabilityApp',
  components: {
    GlAlert,
    GlButton,
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
        if (!authTokens || Object.keys(authTokens).length === 0) {
          return true;
        }

        if (authTokens.status === 'loading') {
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
    sessionEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    queryParams: {
      type: Object,
      required: false,
      default: () => ({}),
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
      bffSessionAttempts: 0,
      authTokensStatus: null,
      provisioningTimedOut: false,
      currentProvisioningMessageIndex: 0,
      provisioningMessageInterval: null,
      isFullscreen: false,
      fullscreenAnnouncementVisible: false,
    };
  },

  computed: {
    iframeUrl() {
      const params = new URLSearchParams(Object.entries(this.queryParams));
      return buildIframeUrl(this.path, this.o11yUrl, params.toString() ? params : null);
    },

    targetPath() {
      const url = new URL(this.iframeUrl);
      return `${url.pathname}${url.search}`;
    },

    needsPolling() {
      if (this.currentAuthTokens?.status === 'loading') return true;
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

    fullscreenAnnouncement() {
      if (this.isFullscreen) {
        return s__('Observability|Entered full screen mode');
      }
      if (this.fullscreenAnnouncementVisible) {
        return s__('Observability|Exited full screen mode');
      }
      return '';
    },

    showFullscreenToggle() {
      return this.isAuthenticated && !this.isLoading;
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
    if (this.sessionEndpoint) {
      // The polling/initializeAuth paths below assume a shared-credential
      // iframe login and can't carry a per-user identity, so when the
      // backend-for-frontend flow is configured (sessionEndpoint set) we take
      // this branch instead: GitLab mints a per-user token out-of-band and we
      // fetch+inject it, skipping the polling/init paths entirely.
      this.fetchBffSession();
    } else if (this.needsPolling) {
      this.startPolling();
    } else {
      this.initializeAuth();
    }
  },

  beforeDestroy() {
    this.pollingCancelled = true;
    clearTimeout(this.iframeReadyTimeout);
    clearTimeout(this.authTimeout);
    this.stopProvisioningMessageCycle();
    iframeNavigator.deregister();
    if (this.isFullscreen) {
      document.removeEventListener('keydown', this.handleFullscreenKeydown);
      document.documentElement.classList.remove('o11y-fullscreen');
    }
    if (this.authManager) {
      this.authManager.destroy();
    }
    window.removeEventListener('message', this.handleMessage);
  },

  methods: {
    toggleFullscreen() {
      this.isFullscreen = !this.isFullscreen;
      this.fullscreenAnnouncementVisible = true;
      document.documentElement.classList.toggle('o11y-fullscreen', this.isFullscreen);
      if (this.isFullscreen) {
        document.addEventListener('keydown', this.handleFullscreenKeydown);
      } else {
        document.removeEventListener('keydown', this.handleFullscreenKeydown);
        this.$nextTick(() => {
          this.$refs.enterFullscreenToggle?.$el?.focus();
        });
      }
    },

    handleFullscreenKeydown(event) {
      if (event.key === 'Escape' && this.isFullscreen) {
        this.toggleFullscreen();
      }
    },

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

      this.authTimeout = setTimeout(() => {
        if (this.isLoading) {
          this.handleAuthError();
        }
      }, TIMEOUTS.AUTH_TIMEOUT);

      window.addEventListener('message', this.handleMessage);
    },

    fetchBffSession() {
      this.isLoading = true;
      this.bffSessionAttempts = 0;

      // Reuse the simplePoll machinery (as startPolling does) so a single
      // transient failure on the session POST retries instead of dropping
      // straight to the error state, and so the pollingCancelled guard
      // prevents acting on responses after the component unmounts.
      simplePoll(
        (continuePolling, stopPolling) => {
          this.requestBffSession(continuePolling, stopPolling);
        },
        { timeout: BFF_SESSION_TIMEOUT },
      )
        .then((tokens) => {
          if (this.pollingCancelled) return;
          this.currentAuthTokens = tokens;
          this.initializeAuth();
        })
        .catch(() => {
          if (this.pollingCancelled) return;
          this.handleAuthError();
        });
    },

    requestBffSession(continuePolling, stopPolling) {
      if (this.pollingCancelled) {
        stopPolling(new Error('CANCELLED'));
        return;
      }

      this.bffSessionAttempts += 1;

      axios
        .post(this.sessionEndpoint)
        .then(({ data }) => {
          if (this.pollingCancelled) {
            stopPolling(new Error('CANCELLED'));
            return;
          }

          const tokens = this.transformTokens(data.auth_tokens);
          if (tokens.accessJwt && tokens.refreshJwt) {
            stopPolling(tokens);
          } else if (this.bffSessionAttempts < MAX_BFF_SESSION_ATTEMPTS) {
            continuePolling();
          } else {
            stopPolling(new Error('MAX_ATTEMPTS'));
          }
        })
        .catch(() => {
          if (this.pollingCancelled) {
            stopPolling(new Error('CANCELLED'));
            return;
          }

          if (this.bffSessionAttempts < MAX_BFF_SESSION_ATTEMPTS) {
            continuePolling();
          } else {
            stopPolling(new Error('MAX_ATTEMPTS'));
          }
        });
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
      clearTimeout(this.authTimeout);
      this.isLoading = false;
      this.isAuthenticated = true;
      iframeNavigator.register(this.$refs.o11yFrame, this.allowedOrigin);
    },

    handleAuthError() {
      clearTimeout(this.authTimeout);
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
    class="o11y-content-wrapper gl-relative gl-h-full gl-grow gl-overflow-hidden gl-rounded-base gl-border-1 gl-border-solid gl-border-default"
  >
    <span aria-live="polite" class="gl-sr-only" data-testid="o11y-fullscreen-announcement">{{
      fullscreenAnnouncement
    }}</span>
    <gl-button
      v-if="showFullscreenToggle && !isFullscreen"
      ref="enterFullscreenToggle"
      icon="maximize"
      :aria-label="s__('Observability|Enter full screen')"
      category="tertiary"
      size="small"
      class="gl-absolute gl-right-3 gl-top-3 gl-z-1"
      data-testid="o11y-enter-fullscreen"
      @click="toggleFullscreen"
    />
    <gl-button
      v-if="showFullscreenToggle && isFullscreen"
      ref="exitFullscreenToggle"
      icon="minimize"
      :aria-label="s__('Observability|Exit full screen')"
      category="tertiary"
      size="small"
      class="gl-absolute gl-right-3 gl-top-3 gl-z-1"
      data-testid="o11y-exit-fullscreen"
      @click="toggleFullscreen"
    />
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
