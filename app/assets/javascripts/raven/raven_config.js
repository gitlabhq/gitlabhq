import Raven from 'raven-js';
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

const IGNORE_URLS = [
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

const SAMPLE_RATE = 95;

const RavenConfig = {
  IGNORE_ERRORS,
  IGNORE_URLS,
  SAMPLE_RATE,
  init(options = {}) {
    this.options = options;

    this.configure();
    this.bindRavenErrors();
    if (this.options.currentUserId) this.setUser();
  },

  configure() {
    Raven.config(this.options.sentryDsn, {
      release: this.options.release,
      tags: this.options.tags,
      whitelistUrls: this.options.whitelistUrls,
      environment: this.options.environment,
      ignoreErrors: this.IGNORE_ERRORS,
      ignoreUrls: this.IGNORE_URLS,
      shouldSendCallback: this.shouldSendSample.bind(this),
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
    const responseText = req.responseText || __('Unknown response text');

    Raven.captureMessage(error, {
      extra: {
        type: config.type,
        url: config.url,
        data: config.data,
        status: req.status,
        response: responseText,
        error,
        event,
      },
    });
  },

  shouldSendSample() {
    return Math.random() * 100 <= this.SAMPLE_RATE;
  },
};

export default RavenConfig;
