import { logError } from '~/lib/logger';
import { s__ } from '~/locale';
import { getSystemColorScheme } from '~/lib/utils/css_utils';
import { MESSAGE_TYPES, TIMEOUTS, RETRY_CONFIG } from '../constants';
import { generateNonce } from './nonce';

const IFRAME_READY_CHECK_DELAY = 50;
const IFRAME_READY_STATE = 'complete';

const ERROR_MESSAGES = {
  INVALID_IFRAME: s__('Observability|Invalid iframe provided'),
  IFRAME_NOT_READY: s__('Observability|Iframe not ready for communication'),
  AUTH_FAILED: s__('Observability|Authentication failed'),
  INVALID_ALLOWED_ORIGIN: s__('Observability|allowedOrigin must be a non-empty string'),
  INVALID_AUTH_TOKENS: s__('Observability|authTokens must be an object'),
  INVALID_TARGET_PATH: s__('Observability|targetPath must be a non-empty string'),
};

const isValidIframe = (iframe) => Boolean(iframe?.contentWindow);

const isIframeReady = (iframe) => {
  try {
    const iframeOrigin = iframe.contentWindow.location.origin;

    if (iframeOrigin === window.location.origin) {
      return iframe.contentWindow.document?.readyState === IFRAME_READY_STATE;
    }
    return true;
  } catch (error) {
    return true;
  }
};

/**
 * Manages authentication for observability iframe communication
 * Handles JWT token exchange with retry logic and exponential backoff
 */
export class AuthManager {
  constructor(allowedOrigin, authTokens, targetPath) {
    AuthManager.validateConstructorParams(allowedOrigin, authTokens, targetPath);

    this.allowedOrigin = allowedOrigin;
    this.authTokens = authTokens;
    this.targetPath = targetPath;
    this.colorMode = AuthManager.determineColorMode();
    this.state = {
      messageNonce: null,
      messageCounter: 0,
      expectedResponseCounter: null,
      retryCount: 0,
      isAuthenticated: false,
    };

    this.callbacks = {
      onAuthSuccess: null,
      onAuthError: null,
    };

    this.messageTimeout = null;
  }

  static validateConstructorParams(allowedOrigin, authTokens, targetPath) {
    if (!allowedOrigin || typeof allowedOrigin !== 'string') {
      throw new Error(ERROR_MESSAGES.INVALID_ALLOWED_ORIGIN);
    }
    if (!authTokens || typeof authTokens !== 'object') {
      throw new Error(ERROR_MESSAGES.INVALID_AUTH_TOKENS);
    }
    if (!targetPath || typeof targetPath !== 'string') {
      throw new Error(ERROR_MESSAGES.INVALID_TARGET_PATH);
    }
  }

  static determineColorMode() {
    const scheme = getSystemColorScheme();
    return scheme === 'gl-dark' ? 'dark' : 'light';
  }

  setCallbacks(onAuthSuccess, onAuthError) {
    this.callbacks.onAuthSuccess = onAuthSuccess;
    this.callbacks.onAuthError = onAuthError;
    return this;
  }

  async sendAuthMessage(iframe, iframeReady = false) {
    try {
      if (!isValidIframe(iframe)) {
        throw new Error(ERROR_MESSAGES.INVALID_IFRAME);
      }

      if (!iframeReady) {
        this.scheduleIframeReadyCheck(iframe);
        return;
      }

      if (!isIframeReady(iframe)) {
        throw new Error(ERROR_MESSAGES.IFRAME_NOT_READY);
      }

      this.prepareMessage();
      this.sendMessage(iframe);
    } catch (error) {
      this.handleAuthenticationError(error);
    }
  }

  scheduleIframeReadyCheck(iframe) {
    setTimeout(() => this.sendAuthMessage(iframe, true), IFRAME_READY_CHECK_DELAY);
  }

  prepareMessage() {
    this.setState({
      messageNonce: generateNonce(),
      messageCounter: this.state.messageCounter + 1,
    });
    this.setState({
      expectedResponseCounter: this.state.messageCounter,
    });
  }

  sendMessage(iframe) {
    const payload = {
      ...this.authTokens,
      nonce: this.state.messageNonce,
      timestamp: Date.now(),
      counter: this.state.messageCounter,
      targetPath: this.targetPath,
      theme: this.colorMode,
    };

    try {
      iframe.contentWindow.postMessage(
        {
          type: MESSAGE_TYPES.JWT_LOGIN,
          payload,
          parentOrigin: window.location.origin,
        },
        this.allowedOrigin,
      );
      this.scheduleRetryTimeout(iframe);
    } catch (error) {
      this.handleAuthenticationError(error);
    }
  }

  scheduleRetryTimeout(iframe) {
    const retryDelay = this.calculateRetryDelay();

    this.messageTimeout = setTimeout(() => {
      if (this.shouldRetry()) {
        this.setState({ retryCount: this.state.retryCount + 1 });
        this.sendAuthMessage(iframe, true);
      } else {
        this.handleAuthenticationError(new Error(ERROR_MESSAGES.AUTH_FAILED));
      }
    }, retryDelay);
  }

  calculateRetryDelay() {
    return (
      TIMEOUTS.BASE_RETRY_DELAY * RETRY_CONFIG.EXPONENTIAL_BACKOFF_BASE ** this.state.retryCount
    );
  }

  shouldRetry() {
    return !this.state.isAuthenticated && this.state.retryCount < RETRY_CONFIG.MAX_RETRIES;
  }

  handleAuthenticationError(error = null) {
    this.setState({ isAuthenticated: false });
    this.cleanupTimeouts();

    if (error) {
      logError(ERROR_MESSAGES.AUTH_FAILED, error);
    }

    this.callbacks.onAuthError?.(error);
  }

  handleAuthSuccess() {
    this.setState({ isAuthenticated: true });
    this.cleanupTimeouts();
    this.callbacks.onAuthSuccess?.();
  }

  setState(updates) {
    this.state = { ...this.state, ...updates };
  }

  resetState() {
    this.setState({
      messageNonce: null,
      messageCounter: 0,
      expectedResponseCounter: null,
      retryCount: 0,
      isAuthenticated: false,
    });
  }

  cleanupTimeouts() {
    if (this.messageTimeout) {
      clearTimeout(this.messageTimeout);
      this.messageTimeout = null;
    }
  }

  destroy() {
    this.cleanupTimeouts();
    this.resetState();
    this.callbacks.onAuthSuccess = null;
    this.callbacks.onAuthError = null;
  }

  getMessageNonce() {
    return this.state.messageNonce;
  }

  getExpectedResponseCounter() {
    return this.state.expectedResponseCounter;
  }

  isAuthSuccessful() {
    return this.state.isAuthenticated;
  }
}
