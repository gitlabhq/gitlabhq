import Raven from 'raven-js';

const RavenConfig = {
  init(options = {}) {
    this.options = options;

    this.configure();
    this.bindRavenErrors();
    if (this.options.currentUserId) this.setUser();
  },

  configure() {
    Raven.config(this.options.sentryDsn, {
      whitelistUrls: this.options.whitelistUrls,
      environment: this.options.isProduction ? 'production' : 'development',
    }).install();
  },

  setUser() {
    Raven.setUserContext({
      id: this.options.currentUserId,
    });
  },

  bindRavenErrors() {
    window.$(document).on('ajaxError.raven', this.handleRavenErrors);
  },

  handleRavenErrors(event, req, config, err) {
    const error = err || req.statusText;
    const responseText = req.responseText || 'Unknown response text';

    Raven.captureMessage(error, {
      extra: {
        type: config.type,
        url: config.url,
        data: config.data,
        status: req.status,
        response: responseText.substring(0, 100),
        error,
        event,
      },
    });
  },
};

export default RavenConfig;
