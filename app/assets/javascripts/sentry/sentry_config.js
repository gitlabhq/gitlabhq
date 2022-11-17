import * as Sentry from '@sentry/browser';
import $ from 'jquery';
import { __ } from '~/locale';
import { IGNORE_ERRORS, DENY_URLS, SAMPLE_RATE } from './constants';

const SentryConfig = {
  IGNORE_ERRORS,
  BLACKLIST_URLS: DENY_URLS,
  SAMPLE_RATE,
  init(options = {}) {
    this.options = options;

    this.configure();
    this.bindSentryErrors();
    if (this.options.currentUserId) this.setUser();
  },

  configure() {
    const { dsn, release, tags, whitelistUrls, environment } = this.options;

    Sentry.init({
      dsn,
      release,
      whitelistUrls,
      environment,
      ignoreErrors: this.IGNORE_ERRORS, // TODO: Remove in favor of https://gitlab.com/gitlab-org/gitlab/issues/35144
      blacklistUrls: this.BLACKLIST_URLS,
      sampleRate: SAMPLE_RATE,
    });

    Sentry.setTags(tags);
  },

  setUser() {
    Sentry.setUser({
      id: this.options.currentUserId,
    });
  },

  bindSentryErrors() {
    $(document).on('ajaxError.sentry', this.handleSentryErrors);
  },

  handleSentryErrors(event, req, config, err) {
    const error = err || req.statusText;
    const { responseText = __('Unknown response text') } = req;
    const { type, url, data } = config;
    const { status } = req;

    Sentry.captureMessage(error, {
      extra: {
        type,
        url,
        data,
        status,
        response: responseText,
        error,
        event,
      },
    });
  },
};

export default SentryConfig;
