import * as Sentry from 'sentrybrowser7';
import { IGNORE_ERRORS, DENY_URLS, SAMPLE_RATE } from './constants';

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
      ignoreErrors: IGNORE_ERRORS,
      denyUrls: DENY_URLS,
      sampleRate: SAMPLE_RATE,
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
