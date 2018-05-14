import $ from 'jquery';
import _ from 'underscore';
import importU2FLibrary from './util';
import U2FError from './error';

// Register U2F (universal 2nd factor) devices for users to authenticate with.
//
// State Flow #1: setup -> in_progress -> registered -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup
export default class U2FRegister {
  constructor(container, u2fParams) {
    this.u2fUtils = null;
    this.container = container;
    this.renderNotSupported = this.renderNotSupported.bind(this);
    this.renderRegistered = this.renderRegistered.bind(this);
    this.renderError = this.renderError.bind(this);
    this.renderInProgress = this.renderInProgress.bind(this);
    this.renderSetup = this.renderSetup.bind(this);
    this.renderTemplate = this.renderTemplate.bind(this);
    this.register = this.register.bind(this);
    this.start = this.start.bind(this);
    this.appId = u2fParams.app_id;
    this.registerRequests = u2fParams.register_requests;
    this.signRequests = u2fParams.sign_requests;

    this.templates = {
      notSupported: '#js-register-u2f-not-supported',
      setup: '#js-register-u2f-setup',
      inProgress: '#js-register-u2f-in-progress',
      error: '#js-register-u2f-error',
      registered: '#js-register-u2f-registered',
    };
  }

  start() {
    return importU2FLibrary()
      .then((utils) => {
        this.u2fUtils = utils;
        this.renderSetup();
      })
      .catch(() => this.renderNotSupported());
  }

  register() {
    return this.u2fUtils.register(this.appId, this.registerRequests, this.signRequests,
      (response) => {
        if (response.errorCode) {
          const error = new U2FError(response.errorCode, 'register');
          return this.renderError(error);
        }
        return this.renderRegistered(JSON.stringify(response));
      }, 10);
  }

  renderTemplate(name, params) {
    const templateString = $(this.templates[name]).html();
    const template = _.template(templateString);
    return this.container.html(template(params));
  }

  renderSetup() {
    this.renderTemplate('setup');
    return this.container.find('#js-setup-u2f-device').on('click', this.renderInProgress);
  }

  renderInProgress() {
    this.renderTemplate('inProgress');
    return this.register();
  }

  renderError(error) {
    this.renderTemplate('error', {
      error_message: error.message(),
      error_code: error.errorCode,
    });
    return this.container.find('#js-u2f-try-again').on('click', this.renderSetup);
  }

  renderRegistered(deviceResponse) {
    this.renderTemplate('registered');
    // Prefer to do this instead of interpolating using Underscore templates
    // because of JSON escaping issues.
    return this.container.find('#js-device-response').val(deviceResponse);
  }

  renderNotSupported() {
    return this.renderTemplate('notSupported');
  }
}
