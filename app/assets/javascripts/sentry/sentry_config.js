import * as Sentry from 'sentrybrowser7';

const SentryConfig = {
  init(options = {}) {
    this.options = options;

    this.configure();
    if (this.options.currentUserId) this.setUser();
  },

  configure() {
    const { dsn, release, tags, allowUrls, environment } = this.options;

    Sentry.init({
      dsn,
      release,
      allowUrls,
      environment,
    });

    Sentry.setTags(tags);
  },

  setUser() {
    Sentry.setUser({
      id: this.options.currentUserId,
    });
  },
};

export default SentryConfig;
