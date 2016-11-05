/* eslint-disable */
// Register U2F (universal 2nd factor) devices for users to authenticate with.
//
// State Flow #1: setup -> in_progress -> registered -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.U2FRegister = (function() {
    function U2FRegister(container, u2fParams) {
      this.container = container;
      this.renderNotSupported = bind(this.renderNotSupported, this);
      this.renderRegistered = bind(this.renderRegistered, this);
      this.renderError = bind(this.renderError, this);
      this.renderInProgress = bind(this.renderInProgress, this);
      this.renderSetup = bind(this.renderSetup, this);
      this.renderTemplate = bind(this.renderTemplate, this);
      this.register = bind(this.register, this);
      this.start = bind(this.start, this);
      this.appId = u2fParams.app_id;
      this.registerRequests = u2fParams.register_requests;
      this.signRequests = u2fParams.sign_requests;
    }

    U2FRegister.prototype.start = function() {
      if (U2FUtil.isU2FSupported()) {
        return this.renderSetup();
      } else {
        return this.renderNotSupported();
      }
    };

    U2FRegister.prototype.register = function() {
      return u2f.register(this.appId, this.registerRequests, this.signRequests, (function(_this) {
        return function(response) {
          var error;
          if (response.errorCode) {
            error = new U2FError(response.errorCode);
            return _this.renderError(error);
          } else {
            return _this.renderRegistered(JSON.stringify(response));
          }
        };
      })(this), 10);
    };

    // Rendering #
    U2FRegister.prototype.templates = {
      "notSupported": "#js-register-u2f-not-supported",
      "setup": '#js-register-u2f-setup',
      "inProgress": '#js-register-u2f-in-progress',
      "error": '#js-register-u2f-error',
      "registered": '#js-register-u2f-registered'
    };

    U2FRegister.prototype.renderTemplate = function(name, params) {
      var template, templateString;
      templateString = $(this.templates[name]).html();
      template = _.template(templateString);
      return this.container.html(template(params));
    };

    U2FRegister.prototype.renderSetup = function() {
      this.renderTemplate('setup');
      return this.container.find('#js-setup-u2f-device').on('click', this.renderInProgress);
    };

    U2FRegister.prototype.renderInProgress = function() {
      this.renderTemplate('inProgress');
      return this.register();
    };

    U2FRegister.prototype.renderError = function(error) {
      this.renderTemplate('error', {
        error_message: error.message(),
        error_code: error.errorCode
      });
      return this.container.find('#js-u2f-try-again').on('click', this.renderSetup);
    };

    U2FRegister.prototype.renderRegistered = function(deviceResponse) {
      this.renderTemplate('registered');
      // Prefer to do this instead of interpolating using Underscore templates
      // because of JSON escaping issues.
      return this.container.find("#js-device-response").val(deviceResponse);
    };

    U2FRegister.prototype.renderNotSupported = function() {
      return this.renderTemplate('notSupported');
    };

    return U2FRegister;

  })();

}).call(this);
