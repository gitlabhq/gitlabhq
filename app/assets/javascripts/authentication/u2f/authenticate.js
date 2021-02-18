import $ from 'jquery';
import { template as lodashTemplate, omit } from 'lodash';
import U2FError from './error';
import importU2FLibrary from './util';

// Authenticate U2F (universal 2nd factor) devices for users to authenticate with.
//
// State Flow #1: setup -> in_progress -> authenticated -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup
export default class U2FAuthenticate {
  constructor(container, form, u2fParams, fallbackButton, fallbackUI) {
    this.u2fUtils = null;
    this.container = container;
    this.renderAuthenticated = this.renderAuthenticated.bind(this);
    this.renderError = this.renderError.bind(this);
    this.renderInProgress = this.renderInProgress.bind(this);
    this.renderTemplate = this.renderTemplate.bind(this);
    this.authenticate = this.authenticate.bind(this);
    this.start = this.start.bind(this);
    this.appId = u2fParams.app_id;
    this.challenge = u2fParams.challenge;
    this.form = form;
    this.fallbackButton = fallbackButton;
    this.fallbackUI = fallbackUI;
    if (this.fallbackButton) {
      this.fallbackButton.addEventListener('click', this.switchToFallbackUI.bind(this));
    }

    // The U2F Javascript API v1.1 requires a single challenge, with
    // _no challenges per-request_. The U2F Javascript API v1.0 requires a
    // challenge per-request, which is done by copying the single challenge
    // into every request.
    //
    // In either case, we don't need the per-request challenges that the server
    // has generated, so we can remove them.
    //
    // Note: The server library fixes this behaviour in (unreleased) version 1.0.0.
    // This can be removed once we upgrade.
    // https://github.com/castle/ruby-u2f/commit/103f428071a81cd3d5f80c2e77d522d5029946a4
    this.signRequests = u2fParams.sign_requests.map((request) => omit(request, 'challenge'));

    this.templates = {
      inProgress: '#js-authenticate-token-2fa-in-progress',
      error: '#js-authenticate-token-2fa-error',
      authenticated: '#js-authenticate-token-2fa-authenticated',
    };
  }

  start() {
    return importU2FLibrary()
      .then((utils) => {
        this.u2fUtils = utils;
        this.renderInProgress();
      })
      .catch(() => this.switchToFallbackUI());
  }

  authenticate() {
    return this.u2fUtils.sign(
      this.appId,
      this.challenge,
      this.signRequests,
      (response) => {
        if (response.errorCode) {
          const error = new U2FError(response.errorCode, 'authenticate');
          return this.renderError(error);
        }
        return this.renderAuthenticated(JSON.stringify(response));
      },
      10,
    );
  }

  renderTemplate(name, params) {
    const templateString = $(this.templates[name]).html();
    const template = lodashTemplate(templateString);
    return this.container.html(template(params));
  }

  renderInProgress() {
    this.renderTemplate('inProgress');
    return this.authenticate();
  }

  renderError(error) {
    this.renderTemplate('error', {
      error_message: error.message(),
      error_name: error.errorCode,
    });
    return this.container.find('#js-token-2fa-try-again').on('click', this.renderInProgress);
  }

  renderAuthenticated(deviceResponse) {
    this.renderTemplate('authenticated');
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
