import { setHTMLFixture } from 'helpers/fixtures';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData } from '~/experimentation/utils';
import Tracking, { initUserTracking, initDefaultTrackers } from '~/tracking';
import getStandardContext from '~/tracking/get_standard_context';

jest.mock('~/experimentation/utils', () => ({ getExperimentData: jest.fn() }));

describe('Tracking', () => {
  let standardContext;
  let snowplowSpy;
  let bindDocumentSpy;
  let trackLoadEventsSpy;
  let enableFormTracking;

  beforeAll(() => {
    window.gl = window.gl || {};
    window.gl.snowplowStandardContext = {
      schema: 'iglu:com.gitlab/gitlab_standard',
      data: {
        environment: 'testing',
        source: 'unknown',
        extra: {},
      },
    };

    standardContext = getStandardContext();
  });

  beforeEach(() => {
    getExperimentData.mockReturnValue(undefined);

    window.snowplow = window.snowplow || (() => {});
    window.snowplowOptions = {
      namespace: '_namespace_',
      hostname: 'app.gitfoo.com',
      cookieDomain: '.gitfoo.com',
    };
    snowplowSpy = jest.spyOn(window, 'snowplow');
  });

  describe('initUserTracking', () => {
    it('calls through to get a new tracker with the expected options', () => {
      initUserTracking();
      expect(snowplowSpy).toHaveBeenCalledWith('newTracker', '_namespace_', 'app.gitfoo.com', {
        namespace: '_namespace_',
        hostname: 'app.gitfoo.com',
        cookieDomain: '.gitfoo.com',
        appId: '',
        userFingerprint: false,
        respectDoNotTrack: true,
        forceSecureTracker: true,
        eventMethod: 'post',
        contexts: { webPage: true, performanceTiming: true },
        formTracking: false,
        linkClickTracking: false,
        pageUnloadTimer: 10,
        formTrackingConfig: {
          fields: { allow: [] },
          forms: { allow: [] },
        },
      });
    });
  });

  describe('initDefaultTrackers', () => {
    beforeEach(() => {
      bindDocumentSpy = jest.spyOn(Tracking, 'bindDocument').mockImplementation(() => null);
      trackLoadEventsSpy = jest.spyOn(Tracking, 'trackLoadEvents').mockImplementation(() => null);
      enableFormTracking = jest
        .spyOn(Tracking, 'enableFormTracking')
        .mockImplementation(() => null);
    });

    it('should activate features based on what has been enabled', () => {
      initDefaultTrackers();
      expect(snowplowSpy).toHaveBeenCalledWith('enableActivityTracking', 30, 30);
      expect(snowplowSpy).toHaveBeenCalledWith('trackPageView', null, [standardContext]);
      expect(snowplowSpy).not.toHaveBeenCalledWith('enableFormTracking');
      expect(snowplowSpy).not.toHaveBeenCalledWith('enableLinkClickTracking');

      window.snowplowOptions = {
        ...window.snowplowOptions,
        formTracking: true,
        linkClickTracking: true,
        formTrackingConfig: { forms: { whitelist: ['foo'] }, fields: { whitelist: ['bar'] } },
      };

      initDefaultTrackers();
      expect(enableFormTracking).toHaveBeenCalledWith(window.snowplowOptions.formTrackingConfig);
      expect(snowplowSpy).toHaveBeenCalledWith('enableLinkClickTracking');
    });

    it('binds the document event handling', () => {
      initDefaultTrackers();
      expect(bindDocumentSpy).toHaveBeenCalled();
    });

    it('tracks page loaded events', () => {
      initDefaultTrackers();
      expect(trackLoadEventsSpy).toHaveBeenCalled();
    });
  });

  describe('.event', () => {
    afterEach(() => {
      window.doNotTrack = undefined;
      navigator.doNotTrack = undefined;
      navigator.msDoNotTrack = undefined;
    });

    it('tracks to snowplow (our current tracking system)', () => {
      Tracking.event('_category_', '_eventName_', { label: '_label_' });

      expect(snowplowSpy).toHaveBeenCalledWith(
        'trackStructEvent',
        '_category_',
        '_eventName_',
        '_label_',
        undefined,
        undefined,
        [standardContext],
      );
    });

    it('allows adding extra data to the default context', () => {
      const extra = { foo: 'bar' };

      Tracking.event('_category_', '_eventName_', { extra });

      expect(snowplowSpy).toHaveBeenCalledWith(
        'trackStructEvent',
        '_category_',
        '_eventName_',
        undefined,
        undefined,
        undefined,
        [
          {
            ...standardContext,
            data: {
              ...standardContext.data,
              extra,
            },
          },
        ],
      );
    });

    it('skips tracking if snowplow is unavailable', () => {
      window.snowplow = false;
      Tracking.event('_category_', '_eventName_');

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('skips tracking if the user does not want to be tracked (general spec)', () => {
      window.doNotTrack = '1';
      Tracking.event('_category_', '_eventName_');

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('skips tracking if the user does not want to be tracked (firefox legacy)', () => {
      navigator.doNotTrack = 'yes';
      Tracking.event('_category_', '_eventName_');

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('skips tracking if the user does not want to be tracked (IE legacy)', () => {
      navigator.msDoNotTrack = '1';
      Tracking.event('_category_', '_eventName_');

      expect(snowplowSpy).not.toHaveBeenCalled();
    });
  });

  describe('.enableFormTracking', () => {
    it('tells snowplow to enable form tracking, with only explicit contexts', () => {
      const config = { forms: { allow: ['form-class1'] }, fields: { allow: ['input-class1'] } };
      Tracking.enableFormTracking(config, ['_passed_context_', standardContext]);

      expect(snowplowSpy).toHaveBeenCalledWith(
        'enableFormTracking',
        { forms: { whitelist: ['form-class1'] }, fields: { whitelist: ['input-class1'] } },
        ['_passed_context_'],
      );
    });

    it('throws an error if no allow rules are provided', () => {
      const expectedError = new Error('Unable to enable form event tracking without allow rules.');

      expect(() => Tracking.enableFormTracking()).toThrow(expectedError);
      expect(() => Tracking.enableFormTracking({ fields: { allow: true } })).toThrow(expectedError);
      expect(() => Tracking.enableFormTracking({ fields: { allow: [] } })).not.toThrow(
        expectedError,
      );
    });

    it('does not add empty form whitelist rules', () => {
      Tracking.enableFormTracking({ fields: { allow: ['input-class1'] } });

      expect(snowplowSpy).toHaveBeenCalledWith(
        'enableFormTracking',
        { fields: { whitelist: ['input-class1'] } },
        [],
      );
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
      Tracking.event('_category_', '_eventName_', { label: '_label_' });

      expect(snowplowSpy).not.toHaveBeenCalled();

      Tracking.flushPendingEvents();

      expect(snowplowSpy).toHaveBeenCalledWith(
        'trackStructEvent',
        '_category_',
        '_eventName_',
        '_label_',
        undefined,
        undefined,
        [standardContext],
      );
    });
  });

  describe.each`
    term
    ${'event'}
    ${'action'}
  `('tracking interface events with data-track-$term', ({ term }) => {
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      Tracking.bindDocument('_category_'); // only happens once
      setHTMLFixture(`
        <input data-track-${term}="click_input1" data-track-label="_label_" value=0 />
        <input data-track-${term}="click_input2" data-track-value=0 value=0/>
        <input type="checkbox" data-track-${term}="toggle_checkbox" value=1 checked/>
        <input class="dropdown" data-track-${term}="toggle_dropdown"/>
        <div data-track-${term}="nested_event"><span class="nested"></span></div>
        <input data-track-bogus="click_bogusinput" data-track-label="_label_" value="_value_"/>
        <input data-track-${term}="click_input3" data-track-experiment="example" value="_value_"/>
        <input data-track-${term}="event_with_extra" data-track-extra='{ "foo": "bar" }' />
        <input data-track-${term}="event_with_invalid_extra" data-track-extra="invalid_json" />
      `);
    });

    it(`binds to clicks on elements matching [data-track-${term}]`, () => {
      document.querySelector(`[data-track-${term}="click_input1"]`).click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input1', {
        label: '_label_',
        value: '0',
      });
    });

    it(`does not bind to clicks on elements without [data-track-${term}]`, () => {
      document.querySelector('[data-track-bogus="click_bogusinput"]').click();

      expect(eventSpy).not.toHaveBeenCalled();
    });

    it('allows value override with the data-track-value attribute', () => {
      document.querySelector(`[data-track-${term}="click_input2"]`).click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input2', {
        value: '0',
      });
    });

    it('handles checkbox values correctly', () => {
      const checkbox = document.querySelector(`[data-track-${term}="toggle_checkbox"]`);

      checkbox.click(); // unchecking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        value: 0,
      });

      checkbox.click(); // checking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        value: '1',
      });
    });

    it('handles bootstrap dropdowns', () => {
      const dropdown = document.querySelector(`[data-track-${term}="toggle_dropdown"]`);

      dropdown.dispatchEvent(new Event('show.bs.dropdown', { bubbles: true }));

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_show', {});

      dropdown.dispatchEvent(new Event('hide.bs.dropdown', { bubbles: true }));

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_hide', {});
    });

    it('handles nested elements inside an element with tracking', () => {
      document.querySelector('span.nested').click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'nested_event', {});
    });

    it('includes experiment data if linked to an experiment', () => {
      const mockExperimentData = {
        variant: 'candidate',
        experiment: 'repo_integrations_link',
        key: '2bff73f6bb8cc11156c50a8ba66b9b8b',
      };
      getExperimentData.mockReturnValue(mockExperimentData);

      document.querySelector(`[data-track-${term}="click_input3"]`).click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input3', {
        value: '_value_',
        context: { schema: TRACKING_CONTEXT_SCHEMA, data: mockExperimentData },
      });
    });

    it('supports extra data as JSON', () => {
      document.querySelector(`[data-track-${term}="event_with_extra"]`).click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'event_with_extra', {
        extra: { foo: 'bar' },
      });
    });

    it('ignores extra if provided JSON is invalid', () => {
      document.querySelector(`[data-track-${term}="event_with_invalid_extra"]`).click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'event_with_invalid_extra', {});
    });
  });

  describe.each`
    term
    ${'event'}
    ${'action'}
  `('tracking page loaded events with -$term', ({ term }) => {
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      setHTMLFixture(`
        <input data-track-${term}="render" data-track-label="label1" value=1 data-track-property="_property_"/>
        <span data-track-${term}="render" data-track-label="label2" data-track-value=1>
          Something
        </span>
        <input data-track-${term}="_render_bogus_" data-track-label="label3" value="_value_" data-track-property="_property_"/>
      `);
      Tracking.trackLoadEvents('_category_'); // only happens once
    });

    it(`sends tracking events when [data-track-${term}="render"] is on an element`, () => {
      expect(eventSpy.mock.calls).toEqual([
        [
          '_category_',
          'render',
          {
            label: 'label1',
            value: '1',
            property: '_property_',
          },
        ],
        [
          '_category_',
          'render',
          {
            label: 'label2',
            value: '1',
          },
        ],
      ]);
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

      it('includes experiment data if linked to an experiment', () => {
        const mockExperimentData = {
          variant: 'candidate',
          experiment: 'darkMode',
        };
        getExperimentData.mockReturnValue(mockExperimentData);

        const mixin = Tracking.mixin({ foo: 'bar', experiment: 'darkMode' });
        expect(mixin.computed.trackingOptions()).toEqual({
          foo: 'bar',
          context: {
            schema: TRACKING_CONTEXT_SCHEMA,
            data: mockExperimentData,
          },
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
