import _ from 'underscore';

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
  formTracking: false,
  linkClickTracking: false,
};

const eventHandler = (e, func, opts = {}) => {
  const el = e.target.closest('[data-track-event]');
  const action = el && el.dataset.trackEvent;
  if (!action) return;

  let value = el.dataset.trackValue || el.value || undefined;
  if (el.type === 'checkbox' && !el.checked) value = false;

  const data = {
    label: el.dataset.trackLabel,
    property: el.dataset.trackProperty,
    value,
    context: el.dataset.trackContext,
  };

  func(opts.category, action + (opts.suffix || ''), _.omit(data, _.isUndefined));
};

const eventHandlers = (category, func) => {
  const handler = opts => e => eventHandler(e, func, { ...{ category }, ...opts });
  const handlers = [];
  handlers.push({ name: 'click', func: handler() });
  handlers.push({ name: 'show.bs.dropdown', func: handler({ suffix: '_show' }) });
  handlers.push({ name: 'hide.bs.dropdown', func: handler({ suffix: '_hide' }) });
  return handlers;
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

  static event(category = document.body.dataset.page, action = 'generic', data = {}) {
    if (!this.enabled()) return false;
    // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
    if (!category) throw new Error('Tracking: no category provided for tracking.');

    const { label, property, value, context } = data;
    const contexts = context ? [context] : undefined;
    return window.snowplow('trackStructEvent', category, action, label, property, value, contexts);
  }

  static bindDocument(category = document.body.dataset.page, documentOverride = null) {
    const el = documentOverride || document;
    if (!this.enabled() || el.trackingBound) return [];

    el.trackingBound = true;

    const handlers = eventHandlers(category, (...args) => this.event(...args));
    handlers.forEach(event => el.addEventListener(event.name, event.func));
    return handlers;
  }

  static mixin(opts = {}) {
    return {
      computed: {
        trackingCategory() {
          const localCategory = this.tracking ? this.tracking.category : null;
          return localCategory || opts.category;
        },
        trackingOptions() {
          return { ...opts, ...this.tracking };
        },
      },
      methods: {
        track(action, data = {}) {
          const category = data.category || this.trackingCategory;
          const options = {
            ...this.trackingOptions,
            ...data,
          };
          Tracking.event(category, action, options);
        },
      },
    };
  }
}

export function initUserTracking() {
  if (!Tracking.enabled()) return;

  const opts = { ...DEFAULT_SNOWPLOW_OPTIONS, ...window.snowplowOptions };
  window.snowplow('newTracker', opts.namespace, opts.hostname, opts);

  window.snowplow('enableActivityTracking', 30, 30);
  window.snowplow('trackPageView'); // must be after enableActivityTracking

  if (opts.formTracking) window.snowplow('enableFormTracking');
  if (opts.linkClickTracking) window.snowplow('enableLinkClickTracking');

  Tracking.bindDocument();
}
