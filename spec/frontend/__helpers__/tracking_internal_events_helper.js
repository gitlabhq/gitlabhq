import { InternalEvents } from '~/tracking';

export function useMockInternalEventsTracking() {
  let originalSnowplow;
  let trackEventSpy;
  let disposables = [];

  const bindInternalEventDocument = (parent = document) => {
    const dispose = InternalEvents.bindInternalEventDocument(parent);
    disposables.push(dispose);

    const triggerEvent = (selectorOrEl, eventName = 'click') => {
      const event = new Event(eventName, { bubbles: true });
      const el =
        typeof selectorOrEl === 'string' ? parent.querySelector(selectorOrEl) : selectorOrEl;

      el.dispatchEvent(event);
    };

    return { triggerEvent, trackEventSpy };
  };

  beforeEach(() => {
    trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');
    originalSnowplow = window.snowplow;
    window.snowplow = () => {};
  });

  afterEach(() => {
    disposables.forEach((dispose) => {
      if (dispose) dispose();
    });
    disposables = [];
    window.snowplow = originalSnowplow;
  });

  return {
    bindInternalEventDocument,
  };
}
