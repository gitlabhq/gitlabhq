(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.U2FAuthenticate = (function() {
    function U2FAuthenticate(container, u2fParams) {
      this.container = container;
      this.renderNotSupported = bind(this.renderNotSupported, this);
      this.renderAuthenticated = bind(this.renderAuthenticated, this);
      this.renderError = bind(this.renderError, this);
      this.renderInProgress = bind(this.renderInProgress, this);
      this.renderSetup = bind(this.renderSetup, this);
      this.renderTemplate = bind(this.renderTemplate, this);
      this.authenticate = bind(this.authenticate, this);
      this.start = bind(this.start, this);
      this.appId = u2fParams.app_id;
      this.challenge = u2fParams.challenge;
      this.signRequests = u2fParams.sign_requests.map(function(request) {
        return _(request).omit('challenge');
      });
    }

    U2FAuthenticate.prototype.start = function() {
      if (U2FUtil.isU2FSupported()) {
        return this.renderSetup();
      } else {
        return this.renderNotSupported();
      }
    };

    U2FAuthenticate.prototype.authenticate = function() {
      return u2f.sign(this.appId, this.challenge, this.signRequests, (function(_this) {
        return function(response) {
          var error;
          if (response.errorCode) {
            error = new U2FError(response.errorCode);
            return _this.renderError(error);
          } else {
            return _this.renderAuthenticated(JSON.stringify(response));
          }
        };
      })(this), 10);
    };

    U2FAuthenticate.prototype.templates = {
      "notSupported": "#js-authenticate-u2f-not-supported",
      "setup": '#js-authenticate-u2f-setup',
      "inProgress": '#js-authenticate-u2f-in-progress',
      "error": '#js-authenticate-u2f-error',
      "authenticated": '#js-authenticate-u2f-authenticated'
    };

    U2FAuthenticate.prototype.renderTemplate = function(name, params) {
      var template, templateString;
      templateString = $(this.templates[name]).html();
      template = _.template(templateString);
      return this.container.html(template(params));
    };

    U2FAuthenticate.prototype.renderSetup = function() {
      this.renderTemplate('setup');
      return this.container.find('#js-login-u2f-device').on('click', this.renderInProgress);
    };

    U2FAuthenticate.prototype.renderInProgress = function() {
      this.renderTemplate('inProgress');
      return this.authenticate();
    };

    U2FAuthenticate.prototype.renderError = function(error) {
      this.renderTemplate('error', {
        error_message: error.message()
      });
      return this.container.find('#js-u2f-try-again').on('click', this.renderSetup);
    };

    U2FAuthenticate.prototype.renderAuthenticated = function(deviceResponse) {
      this.renderTemplate('authenticated');
      return this.container.find("#js-device-response").val(deviceResponse);
    };

    U2FAuthenticate.prototype.renderNotSupported = function() {
      return this.renderTemplate('notSupported');
    };

    return U2FAuthenticate;

  })();

}).call(this);
