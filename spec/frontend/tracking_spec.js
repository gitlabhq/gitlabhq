import $ from 'jquery';
import { setHTMLFixture } from './helpers/fixtures';

import Tracking from '~/tracking';

describe('Tracking', () => {
  beforeEach(() => {
    window.snowplow = window.snowplow || (() => {});
  });

  describe('.event', () => {
    let snowplowSpy = null;

    beforeEach(() => {
      snowplowSpy = jest.spyOn(window, 'snowplow');
    });

    afterEach(() => {
      window.doNotTrack = undefined;
      navigator.doNotTrack = undefined;
      navigator.msDoNotTrack = undefined;
    });

    it('tracks to snowplow (our current tracking system)', () => {
      Tracking.event('_category_', '_eventName_', { label: '_label_' });

      expect(snowplowSpy).toHaveBeenCalledWith('trackStructEvent', '_category_', '_eventName_', {
        label: '_label_',
        property: '',
        value: '',
      });
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
    let eventSpy = null;
    let subject = null;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      subject = new Tracking('_category_');
      setHTMLFixture(`
        <input data-track-event="click_input1" data-track-label="_label_" value="_value_"/>
        <input data-track-event="click_input2" data-track-value="_value_override_" value="_value_"/>
        <input type="checkbox" data-track-event="toggle_checkbox" value="_value_" checked/>
        <input class="dropdown" data-track-event="toggle_dropdown"/>
        <div class="js-projects-list-holder"></div>
      `);
    });

    it('binds to clicks on elements matching [data-track-event]', () => {
      subject.bind(document);
      $('[data-track-event="click_input1"]').click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input1', {
        label: '_label_',
        value: '_value_',
        property: '',
      });
    });

    it('allows value override with the data-track-value attribute', () => {
      subject.bind(document);
      $('[data-track-event="click_input2"]').click();

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'click_input2', {
        label: '',
        value: '_value_override_',
        property: '',
      });
    });

    it('handles checkbox values correctly', () => {
      subject.bind(document);
      const $checkbox = $('[data-track-event="toggle_checkbox"]');

      $checkbox.click(); // unchecking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        label: '',
        property: '',
        value: false,
      });

      $checkbox.click(); // checking

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_checkbox', {
        label: '',
        property: '',
        value: '_value_',
      });
    });

    it('handles bootstrap dropdowns', () => {
      new Tracking('_category_').bind(document);
      const $dropdown = $('[data-track-event="toggle_dropdown"]');

      $dropdown.trigger('show.bs.dropdown'); // showing

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_show', {
        label: '',
        property: '',
        value: '',
      });

      $dropdown.trigger('hide.bs.dropdown'); // hiding

      expect(eventSpy).toHaveBeenCalledWith('_category_', 'toggle_dropdown_hide', {
        label: '',
        property: '',
        value: '',
      });
    });
  });
});
