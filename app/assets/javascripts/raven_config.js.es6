/* global Raven */

/*= require lib/utils/load_script */

(() => {
  const global = window.gl || (window.gl = {});

  class RavenConfig {
    static init(options = {}) {
      this.options = options;
      if (!this.options.sentryDsn || !this.options.ravenAssetUrl) return Promise.reject('sentry dsn and raven asset url is required');
      return global.LoadScript.load(this.options.ravenAssetUrl, 'raven-js')
        .then(() => {
          this.configure();
          this.bindRavenErrors();
          if (this.options.currentUserId) this.setUser();
        });
    }

    static configure() {
      Raven.config(this.options.sentryDsn, {
        whitelistUrls: this.options.whitelistUrls,
        environment: this.options.isProduction ? 'production' : 'development',
      }).install();
    }

    static setUser() {
      Raven.setUserContext({
        id: this.options.currentUserId,
      });
    }

    static bindRavenErrors() {
      $(document).on('ajaxError.raven', this.handleRavenErrors);
    }

    static handleRavenErrors(event, req, config, err) {
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
    }
  }

  global.RavenConfig = RavenConfig;

  document.addEventListener('DOMContentLoaded', () => {
    if (!window.gon) return;

    global.RavenConfig.init({
      sentryDsn: gon.sentry_dsn,
      ravenAssetUrl: gon.raven_asset_url,
      currentUserId: gon.current_user_id,
      whitelistUrls: [gon.gitlab_url],
      isProduction: gon.is_production,
    }).catch($.noop);
  });
})();
