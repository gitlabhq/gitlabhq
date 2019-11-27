import { setHTMLFixture } from './helpers/fixtures';
import Tracking, { initUserTracking } from '~/tracking';

describe('Tracking', () => {
  let snowplowSpy;
  let bindDocumentSpy;

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
    beforeEach(() => {
      bindDocumentSpy = jest.spyOn(Tracking, 'bindDocument').mockImplementation(() => null);
    });

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
        contexts: { webPage: true },
        formTracking: false,
        linkClickTracking: false,
      });
    });

    it('should activate features based on what has been enabled', () => {
      initUserTracking();
      expect(snowplowSpy).toHaveBeenCalledWith('enableActivityTracking', 30, 30);
      expect(snowplowSpy).toHaveBeenCalledWith('trackPageView');
      expect(snowplowSpy).not.toHaveBeenCalledWith('enableFormTracking');
      expect(snowplowSpy).not.toHaveBeenCalledWith('enableLinkClickTracking');

      window.snowplowOptions = Object.assign({}, window.snowplowOptions, {
        formTracking: true,
        linkClickTracking: true,
      });

      initUserTracking();
      expect(snowplowSpy).toHaveBeenCalledWith('enableFormTracking');
      expect(snowplowSpy).toHaveBeenCalledWith('enableLinkClickTracking');
    });

    it('binds the document event handling', () => {
      initUserTracking();
      expect(bindDocumentSpy).toHaveBeenCalled();
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

    const trigger = (selector, eventName = 'click') => {
      const event = new Event(eventName, { bubbles: true });
      document.querySelector(selector).dispatchEvent(event);
    };

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      Tracking.bindDocument('_category_'); // only happens once
      setHTMLFixture(`
        <input data-track-event="click_input1" data-track-label="_label_" value="_value_"/>
        <input data-track-event="click_input2" data-track-value="_value_override_" value="_value_"/>
        <input type="checkbox" data-track-event="toggle_checkbox" value="_value_" checked/>
        <input class="dropdown" data-track-event="toggle_dropdown"/>
        <div data-track-event="nested_event"><span class="nested"></span></div>
      `);
    });

    it('binds to clicks on elements matching [data-track-event]', () => {
      trigger('[data-track-event="click_input1"]');

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input1', {
        label: '_label_',
        value: '_value_',
      });
    });

    it('allows value override with the data-track-value attribute', () => {
      trigger('[data-track-event="click_input2"]');

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input2', {
        value: '_value_override_',
      });
    });

    it('handles checkbox values correctly', () => {
      trigger('[data-track-event="toggle_checkbox"]'); // checking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        value: false,
      });

      trigger('[data-track-event="toggle_checkbox"]'); // unchecking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        value: '_value_',
      });
    });

    it('handles bootstrap dropdowns', () => {
      trigger('[data-track-event="toggle_dropdown"]', 'show.bs.dropdown'); // showing

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_show', {});

      trigger('[data-track-event="toggle_dropdown"]', 'hide.bs.dropdown'); // hiding

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_hide', {});
    });

    it('handles nested elements inside an element with tracking', () => {
      trigger('span.nested', 'click');

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'nested_event', {});
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
