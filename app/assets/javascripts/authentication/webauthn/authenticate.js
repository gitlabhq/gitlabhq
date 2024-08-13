import { WEBAUTHN_AUTHENTICATE } from './constants';
import WebAuthnError from './error';
import WebAuthnFlow from './flow';
import { supported, convertGetParams, convertGetResponse } from './util';

// Authenticate WebAuthn devices for users to authenticate with.
//
// State Flow #1: setup -> in_progress -> authenticated -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup
export default class WebAuthnAuthenticate {
  // eslint-disable-next-line max-params
  constructor(container, form, webauthnParams, fallbackButton, fallbackUI) {
    this.container = container;
    this.webauthnParams = convertGetParams(JSON.parse(webauthnParams.options));
    this.renderInProgress = this.renderInProgress.bind(this);

    this.form = form;
    this.fallbackButton = fallbackButton;
    this.fallbackUI = fallbackUI;
    if (this.fallbackButton) {
      this.fallbackButton.addEventListener('click', this.switchToFallbackUI.bind(this));
    }

    this.flow = new WebAuthnFlow(container, {
      inProgress: '#js-authenticate-token-2fa-in-progress',
      error: '#js-authenticate-token-2fa-error',
      authenticated: '#js-authenticate-token-2fa-authenticated',
    });

    this.container.on('click', '#js-token-2fa-try-again', this.renderInProgress);
  }

  start() {
    if (!supported()) {
      this.switchToFallbackUI();
    } else {
      this.renderInProgress();
    }
  }

  authenticate() {
    navigator.credentials
      .get({ publicKey: this.webauthnParams })
      .then((resp) => {
        const convertedResponse = convertGetResponse(resp);
        this.renderAuthenticated(JSON.stringify(convertedResponse));
      })
      .catch((err) => {
        this.flow.renderError(new WebAuthnError(err, WEBAUTHN_AUTHENTICATE));
      });
  }

  renderInProgress() {
    this.flow.renderTemplate('inProgress');
    this.authenticate();
  }

  renderAuthenticated(deviceResponse) {
    this.flow.renderTemplate('authenticated');
    const container = this.container[0];
    container.querySelector('#js-device-response').value = deviceResponse;
    container.querySelector(this.form).submit();
    this.fallbackButton.classList.add('hidden');
  }

  switchToFallbackUI() {
    this.fallbackButton.classList.add('hidden');
    this.container[0].classList.add('hidden');
    this.fallbackUI.classList.remove('hidden');
  }
}
