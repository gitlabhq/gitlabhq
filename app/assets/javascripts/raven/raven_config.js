import Raven from 'raven-js';
import $ from 'jquery';

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
    $(document).on('ajaxError.raven', this.handleRavenErrors);
  },

  handleRavenErrors(event, req, config, err) {
    const error = err || req.statusText;

    Raven.captureMessage(error, {
      extra: {
        type: config.type,
        url: config.url,
        data: config.data,
        status: req.status,
        response: req.responseText.substring(0, 100),
        error,
        event,
      },
    });
  },
};

export default RavenConfig;
