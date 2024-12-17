import { setHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData, getAllExperimentContexts } from '~/experimentation/utils';
import Tracking, { initUserTracking, initDefaultTrackers } from '~/tracking';
import { REFERRER_TTL, URLS_CACHE_STORAGE_KEY } from '~/tracking/constants';
import getStandardContext from '~/tracking/get_standard_context';

jest.mock('~/experimentation/utils', () => ({
  getExperimentData: jest.fn(),
  getAllExperimentContexts: jest.fn().mockReturnValue([]),
}));

const TEST_CATEGORY = 'root:index';
const TEST_ACTION = 'generic';
const TEST_LABEL = 'button';

describe('Tracking', () => {
  let standardContext;
  let snowplowSpy;

  beforeAll(() => {
    window.gl = window.gl || {};
    window.gl.snowplowUrls = {};
    window.gl.snowplowStandardContext = {
      schema: 'iglu:com.gitlab/gitlab_standard',
      data: {
        environment: 'testing',
        source: 'unknown',
        extra: {},
      },
    };
    window.snowplowOptions = {
      namespace: 'gl_test',
      hostname: 'app.test.com',
      cookieDomain: '.test.com',
      formTracking: true,
      linkClickTracking: true,
      formTrackingConfig: { forms: { allow: ['foo'] }, fields: { allow: ['bar'] } },
    };

    standardContext = getStandardContext();
    window.snowplow = window.snowplow || (() => {});
    document.body.dataset.page = TEST_CATEGORY;

    initUserTracking();
    initDefaultTrackers();
  });

  beforeEach(() => {
    getExperimentData.mockReturnValue(undefined);
    getAllExperimentContexts.mockReturnValue([]);

    snowplowSpy = jest.spyOn(window, 'snowplow');
  });

  describe('.event', () => {
    afterEach(() => {
      window.doNotTrack = undefined;
      navigator.doNotTrack = undefined;
      navigator.msDoNotTrack = undefined;
    });

    it('tracks to snowplow (our current tracking system)', () => {
      Tracking.event(TEST_CATEGORY, TEST_ACTION, { label: TEST_LABEL });

      expect(snowplowSpy).toHaveBeenCalledWith('trackStructEvent', {
        category: TEST_CATEGORY,
        action: TEST_ACTION,
        label: TEST_LABEL,
        property: undefined,
        value: undefined,
        context: [standardContext],
      });
    });

    it('returns `true` if the Snowplow library was called without issues', () => {
      expect(Tracking.event(TEST_CATEGORY, TEST_ACTION)).toBe(true);
    });

    it('returns `false` if the Snowplow library throws an error', () => {
      snowplowSpy.mockImplementation(() => {
        throw new Error();
      });

      expect(Tracking.event(TEST_CATEGORY, TEST_ACTION)).toBe(false);
    });

    it('allows adding extra data to the default context', () => {
      const extra = { foo: 'bar' };

      Tracking.event(TEST_CATEGORY, TEST_ACTION, { extra });

      expect(snowplowSpy).toHaveBeenCalledWith('trackStructEvent', {
        category: TEST_CATEGORY,
        action: TEST_ACTION,
        label: undefined,
        property: undefined,
        value: undefined,
        context: [
          {
            ...standardContext,
            data: {
              ...standardContext.data,
              extra,
            },
          },
        ],
      });
    });

    it('skips tracking if snowplow is unavailable', () => {
      window.snowplow = false;
      Tracking.event(TEST_CATEGORY, TEST_ACTION);

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('skips tracking if the user does not want to be tracked (general spec)', () => {
      window.doNotTrack = '1';
      Tracking.event(TEST_CATEGORY, TEST_ACTION);

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('skips tracking if the user does not want to be tracked (firefox legacy)', () => {
      navigator.doNotTrack = 'yes';
      Tracking.event(TEST_CATEGORY, TEST_ACTION);

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('skips tracking if the user does not want to be tracked (IE legacy)', () => {
      navigator.msDoNotTrack = '1';
      Tracking.event(TEST_CATEGORY, TEST_ACTION);

      expect(snowplowSpy).not.toHaveBeenCalled();
    });
  });

  describe('.enableFormTracking', () => {
    it('tells snowplow to enable form tracking, with only explicit contexts', () => {
      const config = {
        forms: { allow: ['form-class1'] },
        fields: { allow: ['input-class1'] },
      };
      Tracking.enableFormTracking(config, ['_passed_context_', standardContext]);

      expect(snowplowSpy).toHaveBeenCalledWith('enableFormTracking', {
        options: { forms: { allowlist: ['form-class1'] }, fields: { allowlist: ['input-class1'] } },
        context: ['_passed_context_'],
      });
    });

    it('throws an error if no allow rules are provided', () => {
      const expectedError = new Error('Unable to enable form event tracking without allow rules.');

      expect(() => Tracking.enableFormTracking()).toThrow(expectedError);
      expect(() => Tracking.enableFormTracking({ fields: { allow: true } })).toThrow(expectedError);
      expect(() => Tracking.enableFormTracking({ fields: { allow: [] } })).not.toThrow(
        expectedError,
      );
    });

    it('does not add empty form allow rules', () => {
      Tracking.enableFormTracking({ fields: { allow: ['input-class1'] } });

      expect(snowplowSpy).toHaveBeenCalledWith('enableFormTracking', {
        options: { fields: { allowlist: ['input-class1'] } },
        context: [],
      });
    });

    describe('when `document.readyState` does not equal `complete`', () => {
      const originalReadyState = document.readyState;
      const setReadyState = (value) => {
        Object.defineProperty(document, 'readyState', {
          value,
          configurable: true,
        });
      };
      const fireReadyStateChangeEvent = () => {
        document.dispatchEvent(new Event('readystatechange'));
      };

      beforeEach(() => {
        setReadyState('interactive');
      });

      afterEach(() => {
        setReadyState(originalReadyState);
      });

      it('does not call `window.snowplow` until `readystatechange` is fired and `document.readyState` equals `complete`', () => {
        Tracking.enableFormTracking({ fields: { allow: ['input-class1'] } });

        expect(snowplowSpy).not.toHaveBeenCalled();

        fireReadyStateChangeEvent();

        expect(snowplowSpy).not.toHaveBeenCalled();

        setReadyState('complete');
        fireReadyStateChangeEvent();

        expect(snowplowSpy).toHaveBeenCalled();
      });
    });
  });

  describe('.flushPendingEvents', () => {
    it('flushes any pending events', () => {
      Tracking.initialized = false;
      Tracking.event(TEST_CATEGORY, TEST_ACTION, { label: TEST_LABEL });

      expect(snowplowSpy).not.toHaveBeenCalled();

      Tracking.flushPendingEvents();

      expect(snowplowSpy).toHaveBeenCalledWith('trackStructEvent', {
        category: TEST_CATEGORY,
        action: TEST_ACTION,
        label: TEST_LABEL,
        property: undefined,
        value: undefined,
        context: [standardContext],
      });
    });
  });

  describe('.setAnonymousUrls', () => {
    afterEach(() => {
      window.gl.snowplowPseudonymizedPageUrl = '';
      localStorage.removeItem(URLS_CACHE_STORAGE_KEY);
    });

    it('does nothing if URLs are not provided', () => {
      Tracking.setAnonymousUrls();

      expect(snowplowSpy).not.toHaveBeenCalled();
      expect(localStorage.getItem(URLS_CACHE_STORAGE_KEY)).toBe(null);
    });

    it('sets the page URL when provided and populates the cache', () => {
      window.gl.snowplowPseudonymizedPageUrl = TEST_HOST;

      Tracking.setAnonymousUrls();

      expect(snowplowSpy).toHaveBeenCalledWith('setCustomUrl', TEST_HOST);
      expect(JSON.parse(localStorage.getItem(URLS_CACHE_STORAGE_KEY))[0]).toStrictEqual({
        url: TEST_HOST,
        referrer: '',
        originalUrl: window.location.href,
        timestamp: Date.now(),
      });
    });

    it('does not appends the hash/fragment to the pseudonymized URL', () => {
      window.gl.snowplowPseudonymizedPageUrl = TEST_HOST;
      window.location.hash = 'first-heading';

      Tracking.setAnonymousUrls();

      expect(snowplowSpy).toHaveBeenCalledWith('setCustomUrl', TEST_HOST);
    });

    describe('allowed hashes/fragments', () => {
      it.each`
        hash                  | appends  | description
        ${'note_abc_123'}     | ${true}  | ${'appends'}
        ${'diff-content-819'} | ${true}  | ${'appends'}
        ${'first_heading'}    | ${false} | ${'does not append'}
      `('$description `$hash` hash', ({ hash, appends }) => {
        window.gl.snowplowPseudonymizedPageUrl = TEST_HOST;
        window.location.hash = hash;

        Tracking.setAnonymousUrls();

        const url = appends ? `${TEST_HOST}#${hash}` : TEST_HOST;
        expect(snowplowSpy).toHaveBeenCalledWith('setCustomUrl', url);
      });
    });

    it('does not set the referrer URL by default', () => {
      window.gl.snowplowPseudonymizedPageUrl = TEST_HOST;

      Tracking.setAnonymousUrls();

      expect(snowplowSpy).not.toHaveBeenCalledWith('setReferrerUrl', expect.any(String));
    });

    describe('with referrers cache', () => {
      const testUrl = '/namespace:1/project:2/-/merge_requests/5';
      const testOriginalUrl = '/my-namespace/my-project/-/merge_requests/';
      const setUrlsCache = (data) =>
        localStorage.setItem(URLS_CACHE_STORAGE_KEY, JSON.stringify(data));

      beforeEach(() => {
        window.gl.snowplowPseudonymizedPageUrl = TEST_HOST;
        Object.defineProperty(document, 'referrer', { value: '', configurable: true });
      });

      it('does nothing if a referrer can not be found', () => {
        setUrlsCache([
          {
            url: testUrl,
            originalUrl: TEST_HOST,
            timestamp: Date.now(),
          },
        ]);

        Tracking.setAnonymousUrls();

        expect(snowplowSpy).not.toHaveBeenCalledWith('setReferrerUrl', expect.any(String));
      });

      it('sets referrer URL from the page URL found in cache', () => {
        Object.defineProperty(document, 'referrer', { value: testOriginalUrl });
        setUrlsCache([
          {
            url: testUrl,
            originalUrl: testOriginalUrl,
            timestamp: Date.now(),
          },
        ]);

        Tracking.setAnonymousUrls();

        expect(snowplowSpy).toHaveBeenCalledWith('setReferrerUrl', testUrl);
      });

      it('ignores and removes old entries from the cache', () => {
        window.gl.maskedDefaultReferrerUrl =
          'https://gitlab.com/namespace:#/project:#/-/merge_requests/';
        const oldTimestamp = Date.now() - (REFERRER_TTL + 1);
        Object.defineProperty(document, 'referrer', { value: testOriginalUrl });
        setUrlsCache([
          {
            url: testUrl,
            originalUrl: testOriginalUrl,
            timestamp: oldTimestamp,
          },
        ]);

        Tracking.setAnonymousUrls();

        expect(snowplowSpy).toHaveBeenCalledWith(
          'setReferrerUrl',
          window.gl.maskedDefaultReferrerUrl,
        );
        expect(localStorage.getItem(URLS_CACHE_STORAGE_KEY)).not.toContain(oldTimestamp.toString());
      });

      it('sets the referrer URL to maskedDefaultReferrerUrl if no referrer is found in cache', () => {
        window.gl.maskedDefaultReferrerUrl =
          'https://gitlab.com/namespace:#/project:#/-/merge_requests/';
        setUrlsCache([]);

        Object.defineProperty(document, 'referrer', {
          value: 'https://gitlab.com/my-namespace/my-project/-/merge_requests/',
        });

        Tracking.setAnonymousUrls();

        expect(snowplowSpy).toHaveBeenCalledWith(
          'setReferrerUrl',
          window.gl.maskedDefaultReferrerUrl,
        );
      });
    });
  });

  describe('tracking interface events with data-track-action', () => {
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      setHTMLFixture(`
        <input data-track-action="click_input1" data-track-label="button" value="0" />
        <input data-track-action="click_input2" data-track-value="0" value="0" />
        <input type="checkbox" data-track-action="toggle_checkbox" value=1 checked />
        <input class="dropdown" data-track-action="toggle_dropdown"/>
        <div data-track-action="nested_event"><span class="nested"></span></div>
        <input data-track-bogus="click_bogusinput" data-track-label="button" value="1" />
        <input data-track-action="click_input3" data-track-experiment="example" value="1" />
        <input data-track-action="event_with_extra" data-track-extra='{ "foo": "bar" }' />
        <input data-track-action="event_with_invalid_extra" data-track-extra="invalid_json" />
      `);
    });

    it(`binds to clicks on elements matching [data-track-action]`, () => {
      document.querySelector(`[data-track-action="click_input1"]`).click();

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'click_input1', {
        label: TEST_LABEL,
        value: '0',
      });
    });

    it(`does not bind to clicks on elements without [data-track-action]`, () => {
      document.querySelector('[data-track-bogus="click_bogusinput"]').click();

      expect(eventSpy).not.toHaveBeenCalled();
    });

    it('allows value override with the data-track-value attribute', () => {
      document.querySelector(`[data-track-action="click_input2"]`).click();

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'click_input2', {
        value: '0',
      });

      expect(snowplowSpy).toHaveBeenCalledWith('trackStructEvent', {
        category: TEST_CATEGORY,
        action: 'click_input2',
        label: undefined,
        property: undefined,
        value: 0,
        context: [standardContext],
      });
    });

    it('handles checkbox values correctly', () => {
      const checkbox = document.querySelector(`[data-track-action="toggle_checkbox"]`);

      checkbox.click(); // unchecking

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'toggle_checkbox', {
        value: 0,
      });

      checkbox.click(); // checking

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'toggle_checkbox', {
        value: '1',
      });
    });

    it('handles bootstrap dropdowns', () => {
      const dropdown = document.querySelector(`[data-track-action="toggle_dropdown"]`);

      dropdown.dispatchEvent(new Event('show.bs.dropdown', { bubbles: true }));

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'toggle_dropdown_show', {});

      dropdown.dispatchEvent(new Event('hide.bs.dropdown', { bubbles: true }));

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'toggle_dropdown_hide', {});
    });

    it('handles nested elements inside an element with tracking', () => {
      document.querySelector('span.nested').click();

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'nested_event', {});
    });

    it('includes experiment data if linked to an experiment', () => {
      const mockExperimentData = {
        variant: 'candidate',
        experiment: 'example',
        key: '2bff73f6bb8cc11156c50a8ba66b9b8b',
      };
      getExperimentData.mockReturnValue(mockExperimentData);

      document.querySelector(`[data-track-action="click_input3"]`).click();

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'click_input3', {
        value: '1',
        context: { schema: TRACKING_CONTEXT_SCHEMA, data: mockExperimentData },
      });
    });

    it('supports extra data as JSON', () => {
      document.querySelector(`[data-track-action="event_with_extra"]`).click();

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'event_with_extra', {
        extra: { foo: 'bar' },
      });
    });

    it('ignores extra if provided JSON is invalid', () => {
      document.querySelector(`[data-track-action="event_with_invalid_extra"]`).click();

      expect(eventSpy).toHaveBeenCalledWith(TEST_CATEGORY, 'event_with_invalid_extra', {});
    });
  });

  describe('tracking page loaded events with -action', () => {
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      setHTMLFixture(`
        <div data-track-action="click_link" data-track-label="all_nested_links">
          <input data-track-action="render" data-track-label="label1" value=1 data-track-property="_property_" />
          <span data-track-action="render" data-track-label="label2" data-track-value="1">
            <a href="#" id="link">Something</a>
          </span>
          <input data-track-action="_render_bogus_" data-track-label="label3" value="_value_" data-track-property="_property_" />
        </div>
      `);
      Tracking.trackLoadEvents(TEST_CATEGORY);
    });

    it(`sends tracking events when [data-track-action="render"] is on an element`, () => {
      expect(eventSpy.mock.calls).toEqual([
        [
          TEST_CATEGORY,
          'render',
          {
            label: 'label1',
            value: '1',
            property: '_property_',
          },
        ],
        [
          TEST_CATEGORY,
          'render',
          {
            label: 'label2',
            value: '1',
          },
        ],
      ]);
    });

    describe.each`
      event                 | actionSuffix
      ${'click'}            | ${''}
      ${'show.bs.dropdown'} | ${'_show'}
      ${'hide.bs.dropdown'} | ${'_hide'}
    `(`auto-tracking $event events on nested elements`, ({ event, actionSuffix }) => {
      let link;

      beforeEach(() => {
        link = document.querySelector('#link');
        eventSpy.mockClear();
      });

      it(`avoids using ancestor [data-track-action="render"] tracking configurations`, () => {
        link.dispatchEvent(new Event(event, { bubbles: true }));

        expect(eventSpy).not.toHaveBeenCalledWith(
          TEST_CATEGORY,
          `render${actionSuffix}`,
          expect.any(Object),
        );
        expect(eventSpy).toHaveBeenCalledWith(
          TEST_CATEGORY,
          `click_link${actionSuffix}`,
          expect.objectContaining({ label: 'all_nested_links' }),
        );
      });
    });
  });

  describe('tracking mixin', () => {
    describe('trackingOptions', () => {
      it('returns the options defined on initialisation', () => {
        const mixin = Tracking.mixin({ foo: 'bar' });
        expect(mixin.computed.trackingOptions()).toEqual({ foo: 'bar' });
      });

      it('lets local tracking value override and extend options', () => {
        const mixin = Tracking.mixin({ foo: 'bar' });
        // The value of this in the Vue lifecyle is different, but this serves the test's purposes
        mixin.computed.tracking = { foo: 'baz', baz: 'bar' };
        expect(mixin.computed.trackingOptions()).toEqual({ foo: 'baz', baz: 'bar' });
      });

      describe('experiment', () => {
        const mockExperimentData = {
          variant: 'candidate',
          experiment: 'darkMode',
        };

        const expectedOptions = {
          foo: 'bar',
          context: {
            schema: TRACKING_CONTEXT_SCHEMA,
            data: mockExperimentData,
          },
        };

        beforeEach(() => {
          getExperimentData.mockReturnValue(mockExperimentData);
        });

        it('includes experiment data if linked to an experiment', () => {
          const mixin = Tracking.mixin({ foo: 'bar', experiment: 'darkMode' });

          expect(mixin.computed.trackingOptions()).toEqual(expectedOptions);
        });

        it('includes experiment data if local tracking value provides experiment name', () => {
          const mixin = Tracking.mixin({ foo: 'bar' });
          mixin.computed.tracking = { experiment: 'darkMode' };

          expect(mixin.computed.trackingOptions()).toEqual(expectedOptions);
        });
      });

      it('does not include experiment data if experiment data does not exist', () => {
        const mixin = Tracking.mixin({ foo: 'bar', experiment: 'lightMode' });
        expect(mixin.computed.trackingOptions()).toEqual({
          foo: 'bar',
        });
      });
    });

    describe('trackingCategory', () => {
      it('returns the category set in the component properties first', () => {
        const mixin = Tracking.mixin({ category: 'foo' });
        mixin.computed.tracking = {
          category: 'bar',
        };
        expect(mixin.computed.trackingCategory()).toBe('bar');
      });

      it('returns the category set in the options', () => {
        const mixin = Tracking.mixin({ category: 'foo' });
        expect(mixin.computed.trackingCategory()).toBe('foo');
      });

      it('returns undefined if no category is selected', () => {
        const mixin = Tracking.mixin();
        expect(mixin.computed.trackingCategory()).toBe(undefined);
      });
    });

    describe('track', () => {
      let eventSpy;
      let mixin;

      beforeEach(() => {
        eventSpy = jest.spyOn(Tracking, 'event').mockReturnValue();
        mixin = Tracking.mixin();
        mixin = {
          ...mixin.computed,
          ...mixin.methods,
        };
      });

      it('calls the event method with no category or action defined', () => {
        mixin.trackingCategory = mixin.trackingCategory();
        mixin.trackingOptions = mixin.trackingOptions();

        mixin.track();
        expect(eventSpy).toHaveBeenCalledWith(undefined, undefined, {});
      });

      it('calls the event method', () => {
        mixin.trackingCategory = mixin.trackingCategory();
        mixin.trackingOptions = mixin.trackingOptions();

        mixin.track('foo');
        expect(eventSpy).toHaveBeenCalledWith(undefined, 'foo', {});
      });

      it('gives precedence to data for category and options', () => {
        mixin.trackingCategory = mixin.trackingCategory();
        mixin.trackingOptions = mixin.trackingOptions();
        const data = { category: 'foo', label: 'baz' };
        mixin.track('foo', data);
        expect(eventSpy).toHaveBeenCalledWith('foo', 'foo', data);
      });
    });
  });
});
