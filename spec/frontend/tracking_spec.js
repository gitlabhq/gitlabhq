import { setHTMLFixture } from './helpers/fixtures';
import Tracking, { initUserTracking, initDefaultTrackers } from '~/tracking';

describe('Tracking', () => {
  let snowplowSpy;
  let bindDocumentSpy;
  let trackLoadEventsSpy;

  beforeEach(() => {
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
      });
    });
  });

  describe('initDefaultTrackers', () => {
    beforeEach(() => {
      bindDocumentSpy = jest.spyOn(Tracking, 'bindDocument').mockImplementation(() => null);
      trackLoadEventsSpy = jest.spyOn(Tracking, 'trackLoadEvents').mockImplementation(() => null);
    });

    it('should activate features based on what has been enabled', () => {
      initDefaultTrackers();
      expect(snowplowSpy).toHaveBeenCalledWith('enableActivityTracking', 30, 30);
      expect(snowplowSpy).toHaveBeenCalledWith('trackPageView');
      expect(snowplowSpy).not.toHaveBeenCalledWith('enableFormTracking');
      expect(snowplowSpy).not.toHaveBeenCalledWith('enableLinkClickTracking');

      window.snowplowOptions = {
        ...window.snowplowOptions,
        formTracking: true,
        linkClickTracking: true,
      };

      initDefaultTrackers();
      expect(snowplowSpy).toHaveBeenCalledWith('enableFormTracking');
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
        undefined,
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

  describe('tracking interface events', () => {
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      Tracking.bindDocument('_category_'); // only happens once
      setHTMLFixture(`
        <input data-track-event="click_input1" data-track-label="_label_" value="_value_"/>
        <input data-track-event="click_input2" data-track-value="_value_override_" value="_value_"/>
        <input type="checkbox" data-track-event="toggle_checkbox" value="_value_" checked/>
        <input class="dropdown" data-track-event="toggle_dropdown"/>
        <div data-track-event="nested_event"><span class="nested"></span></div>
        <input data-track-eventbogus="click_bogusinput" data-track-label="_label_" value="_value_"/>
      `);
    });

    it('binds to clicks on elements matching [data-track-event]', () => {
      document.querySelector('[data-track-event="click_input1"]').click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input1', {
        label: '_label_',
        value: '_value_',
      });
    });

    it('does not bind to clicks on elements without [data-track-event]', () => {
      document.querySelector('[data-track-eventbogus="click_bogusinput"]').click();

      expect(eventSpy).not.toHaveBeenCalled();
    });

    it('allows value override with the data-track-value attribute', () => {
      document.querySelector('[data-track-event="click_input2"]').click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input2', {
        value: '_value_override_',
      });
    });

    it('handles checkbox values correctly', () => {
      const checkbox = document.querySelector('[data-track-event="toggle_checkbox"]');

      checkbox.click(); // unchecking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        value: false,
      });

      checkbox.click(); // checking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        value: '_value_',
      });
    });

    it('handles bootstrap dropdowns', () => {
      const dropdown = document.querySelector('[data-track-event="toggle_dropdown"]');

      dropdown.dispatchEvent(new Event('show.bs.dropdown', { bubbles: true }));

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_show', {});

      dropdown.dispatchEvent(new Event('hide.bs.dropdown', { bubbles: true }));

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_hide', {});
    });

    it('handles nested elements inside an element with tracking', () => {
      document.querySelector('span.nested').click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'nested_event', {});
    });
  });

  describe('tracking page loaded events', () => {
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      setHTMLFixture(`
        <input data-track-event="render" data-track-label="label1" value="_value_" data-track-property="_property_"/>
        <span data-track-event="render" data-track-label="label2" data-track-value="_value_">
          Something
        </span>
        <input data-track-event="_render_bogus_" data-track-label="label3" value="_value_" data-track-property="_property_"/>
      `);
      Tracking.trackLoadEvents('_category_'); // only happens once
    });

    it('sends tracking events when [data-track-event="render"] is on an element', () => {
      expect(eventSpy.mock.calls).toEqual([
        [
          '_category_',
          'render',
          {
            label: 'label1',
            value: '_value_',
            property: '_property_',
          },
        ],
        [
          '_category_',
          'render',
          {
            label: 'label2',
            value: '_value_',
          },
        ],
      ]);
    });
  });

  describe('tracking mixin', () => {
    describe('trackingOptions', () => {
      it('return the options defined on initialisation', () => {
        const mixin = Tracking.mixin({ foo: 'bar' });
        expect(mixin.computed.trackingOptions()).toEqual({ foo: 'bar' });
      });

      it('local tracking value override and extend options', () => {
        const mixin = Tracking.mixin({ foo: 'bar' });
        //  the value of this in the  vue lifecyle is different, but this serve the tests purposes
        mixin.computed.tracking = { foo: 'baz', baz: 'bar' };
        expect(mixin.computed.trackingOptions()).toEqual({ foo: 'baz', baz: 'bar' });
      });
    });

    describe('trackingCategory', () => {
      it('return the category set in the component properties first', () => {
        const mixin = Tracking.mixin({ category: 'foo' });
        mixin.computed.tracking = {
          category: 'bar',
        };
        expect(mixin.computed.trackingCategory()).toBe('bar');
      });

      it('return the category set in the options', () => {
        const mixin = Tracking.mixin({ category: 'foo' });
        expect(mixin.computed.trackingCategory()).toBe('foo');
      });

      it('if no category is selected returns undefined', () => {
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

      it('give precedence to data for category and options', () => {
        mixin.trackingCategory = mixin.trackingCategory();
        mixin.trackingOptions = mixin.trackingOptions();
        const data = { category: 'foo', label: 'baz' };
        mixin.track('foo', data);
        expect(eventSpy).toHaveBeenCalledWith('foo', 'foo', data);
      });
    });
  });
});
