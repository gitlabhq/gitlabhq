import $ from 'jquery';

const DEFAULT_SNOWPLOW_OPTIONS = {
  namespace: 'gl',
  hostname: window.location.hostname,
  cookieDomain: window.location.hostname,
  appId: '',
  userFingerprint: false,
  respectDoNotTrack: true,
  forceSecureTracker: true,
  eventMethod: 'post',
  contexts: { webPage: true },
  // Page tracking tracks a single event when the page loads.
  pageTrackingEnabled: false,
  // Activity tracking tracks when a user is still interacting with the page.
  // Events like scrolling and mouse movements are used to determine if the
  // user has the tab active and is still actively engaging.
  activityTrackingEnabled: false,
};

const extractData = (el, opts = {}) => {
  const { trackEvent, trackLabel = '', trackProperty = '' } = el.dataset;
  let trackValue = el.dataset.trackValue || el.value || '';
  if (el.type === 'checkbox' && !el.checked) trackValue = false;
  return [
    trackEvent + (opts.suffix || ''),
    {
      label: trackLabel,
      property: trackProperty,
      value: trackValue,
    },
  ];
};

export default class Tracking {
  static trackable() {
    return !['1', 'yes'].includes(
      window.doNotTrack || navigator.doNotTrack || navigator.msDoNotTrack,
    );
  }

  static enabled() {
    return typeof window.snowplow === 'function' && this.trackable();
  }

  static event(category = document.body.dataset.page, event = 'generic', data = {}) {
    if (!this.enabled()) return false;
    // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
    if (!category) throw new Error('Tracking: no category provided for tracking.');

    return window.snowplow(
      'trackStructEvent',
      category,
      event,
      Object.assign({}, { label: '', property: '', value: '' }, data),
    );
  }

  constructor(category = document.body.dataset.page) {
    this.category = category;
  }

  bind(container = document) {
    if (!this.constructor.enabled()) return;
    container.querySelectorAll(`[data-track-event]`).forEach(el => {
      if (this.customHandlingFor(el)) return;
      // jquery is required for select2, so we use it always
      // see: https://github.com/select2/select2/issues/4686
      $(el).on('click', this.eventHandler(this.category));
    });
  }

  customHandlingFor(el) {
    const classes = el.classList;

    // bootstrap dropdowns
    if (classes.contains('dropdown')) {
      $(el).on('show.bs.dropdown', this.eventHandler(this.category, { suffix: '_show' }));
      $(el).on('hide.bs.dropdown', this.eventHandler(this.category, { suffix: '_hide' }));
      return true;
    }

    return false;
  }

  eventHandler(category = null, opts = {}) {
    return e => {
      this.constructor.event(category || this.category, ...extractData(e.currentTarget, opts));
    };
  }
}

export function initUserTracking() {
  if (!Tracking.enabled()) return;

  const opts = Object.assign({}, DEFAULT_SNOWPLOW_OPTIONS, window.snowplowOptions);
  window.snowplow('newTracker', opts.namespace, opts.hostname, opts);

  if (opts.activityTrackingEnabled) window.snowplow('enableActivityTracking', 30, 30);
  if (opts.pageTrackingEnabled) window.snowplow('trackPageView'); // must be after enableActivityTracking
}
