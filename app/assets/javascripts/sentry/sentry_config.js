import * as Sentry from '@sentry/browser';
import $ from 'jquery';
import { __ } from '~/locale';

const IGNORE_ERRORS = [
  // Random plugins/extensions
  'top.GLOBALS',
  // See: http://blog.errorception.com/2012/03/tale-of-unfindable-js-error. html
  'originalCreateNotification',
  'canvas.contentDocument',
  'MyApp_RemoveAllHighlights',
  'http://tt.epicplay.com',
  __("Can't find variable: ZiteReader"),
  __('jigsaw is not defined'),
  __('ComboSearch is not defined'),
  'http://loading.retry.widdit.com/',
  'atomicFindClose',
  // Facebook borked
  'fb_xd_fragment',
  // ISP "optimizing" proxy - `Cache-Control: no-transform` seems to
  // reduce this. (thanks @acdha)
  // See http://stackoverflow.com/questions/4113268
  'bmi_SafeAddOnload',
  'EBCallBackMessageReceived',
  // See http://toolbar.conduit.com/Developer/HtmlAndGadget/Methods/JSInjection.aspx
  'conduitPage',
];

const BLACKLIST_URLS = [
  // Facebook flakiness
  /graph\.facebook\.com/i,
  // Facebook blocked
  /connect\.facebook\.net\/en_US\/all\.js/i,
  // Woopra flakiness
  /eatdifferent\.com\.woopra-ns\.com/i,
  /static\.woopra\.com\/js\/woopra\.js/i,
  // Chrome extensions
  /extensions\//i,
  /^chrome:\/\//i,
  // Other plugins
  /127\.0\.0\.1:4001\/isrunning/i, // Cacaoweb
  /webappstoolbarba\.texthelp\.com\//i,
  /metrics\.itunes\.apple\.com\.edgesuite\.net\//i,
];

const SAMPLE_RATE = 0.95;

const SentryConfig = {
  IGNORE_ERRORS,
  BLACKLIST_URLS,
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
