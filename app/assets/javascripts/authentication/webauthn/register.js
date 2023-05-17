import { __ } from '~/locale';
import WebAuthnError from './error';
import WebAuthnFlow from './flow';
import { supported, isHTTPS, convertCreateParams, convertCreateResponse } from './util';
import { WEBAUTHN_REGISTER } from './constants';

// Register WebAuthn devices for users to authenticate with.
//
// State Flow #1: setup -> in_progress -> registered -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup
export default class WebAuthnRegister {
  constructor(container, webauthnParams) {
    this.container = container;
    this.renderInProgress = this.renderInProgress.bind(this);
    this.webauthnOptions = convertCreateParams(webauthnParams.options);

    this.flow = new WebAuthnFlow(container, {
      message: '#js-register-2fa-message',
      setup: '#js-register-token-2fa-setup',
      error: '#js-register-token-2fa-error',
      registered: '#js-register-token-2fa-registered',
    });

    this.container.on('click', '#js-token-2fa-try-again', this.renderInProgress);
  }

  start() {
    if (!supported()) {
      // we show a special error message when the user visits the site
      // using a non-ssl connection as this makes WebAuthn unavailable in
      // any case, regardless of the used browser
      this.renderNotSupported(!isHTTPS());
    } else {
      this.renderSetup();
    }
  }

  register() {
    navigator.credentials
      .create({
        publicKey: this.webauthnOptions,
      })
      .then((cred) => this.renderRegistered(JSON.stringify(convertCreateResponse(cred))))
      .catch((err) => this.flow.renderError(new WebAuthnError(err, WEBAUTHN_REGISTER)));
  }

  renderSetup() {
    this.flow.renderTemplate('setup');
    this.container.find('#js-setup-token-2fa-device').on('click', this.renderInProgress);
  }

  renderInProgress() {
    this.flow.renderTemplate('message', {
      message: __(
        'Trying to communicate with your device. Plug it in (if needed) and press the button on the device now.',
      ),
    });
    return this.register();
  }

  renderRegistered(deviceResponse) {
    this.flow.renderTemplate('registered');
    // Prefer to do this instead of interpolating using Underscore templates
    // because of JSON escaping issues.
    this.container.find('#js-device-response').val(deviceResponse);
  }

  renderNotSupported(noHttps) {
    const message = noHttps
      ? __(
          'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.',
        )
      : __(
          "Your browser doesn't support WebAuthn. Please use a supported browser, e.g. Chrome (67+) or Firefox (60+).",
        );

    this.flow.renderTemplate('message', { message });
  }
}
