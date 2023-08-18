import API from '~/api';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InternalEvents from '~/tracking/internal_events';
import {
  GITLAB_INTERNAL_EVENT_CATEGORY,
  SERVICE_PING_SCHEMA,
  LOAD_INTERNAL_EVENTS_SELECTOR,
} from '~/tracking/constants';
import * as utils from '~/tracking/utils';
import { Tracker } from '~/tracking/tracker';

jest.mock('~/api', () => ({
  trackInternalEvent: jest.fn(),
}));

jest.mock('~/tracking/utils', () => ({
  ...jest.requireActual('~/tracking/utils'),
  getInternalEventHandlers: jest.fn(),
}));

Tracker.enabled = jest.fn();

describe('InternalEvents', () => {
  describe('track_event', () => {
    it('track_event calls API.trackInternalEvent with correct arguments', () => {
      const event = 'TestEvent';

      InternalEvents.track_event(event);

      expect(API.trackInternalEvent).toHaveBeenCalledTimes(1);
      expect(API.trackInternalEvent).toHaveBeenCalledWith(event);
    });

    it('track_event calls tracking.event functions with correct arguments', () => {
      const trackingSpy = mockTracking(GITLAB_INTERNAL_EVENT_CATEGORY, undefined, jest.spyOn);

      const event = 'TestEvent';

      InternalEvents.track_event(event);

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(GITLAB_INTERNAL_EVENT_CATEGORY, event, {
        context: {
          schema: SERVICE_PING_SCHEMA,
          data: {
            event_name: event,
            data_source: 'redis_hll',
          },
        },
      });
    });
  });

  describe('mixin', () => {
    let wrapper;

    beforeEach(() => {
      const Component = {
        render() {},
        mixins: [InternalEvents.mixin()],
      };
      wrapper = shallowMountExtended(Component);
    });

    it('this.track_event function calls InternalEvent`s track function with an event', () => {
      const event = 'TestEvent';
      const trackEventSpy = jest.spyOn(InternalEvents, 'track_event');

      wrapper.vm.track_event(event);

      expect(trackEventSpy).toHaveBeenCalledTimes(1);
      expect(trackEventSpy).toHaveBeenCalledWith(event);
    });
  });

  describe('bindInternalEventDocument', () => {
    it('should not bind event handlers if tracker is not enabled', () => {
      Tracker.enabled.mockReturnValue(false);
      const result = InternalEvents.bindInternalEventDocument();
      expect(result).toEqual([]);
      expect(utils.getInternalEventHandlers).not.toHaveBeenCalled();
    });

    it('should not bind event handlers if already bound', () => {
      Tracker.enabled.mockReturnValue(true);
      document.internalEventsTrackingBound = true;
      const result = InternalEvents.bindInternalEventDocument();
      expect(result).toEqual([]);
      expect(utils.getInternalEventHandlers).not.toHaveBeenCalled();
    });

    it('should bind event handlers when not bound yet', () => {
      Tracker.enabled.mockReturnValue(true);
      document.internalEventsTrackingBound = false;
      const addEventListenerMock = jest.spyOn(document, 'addEventListener');

      const result = InternalEvents.bindInternalEventDocument();

      expect(addEventListenerMock).toHaveBeenCalledWith('click', expect.any(Function));
      expect(result).toEqual({ name: 'click', func: expect.any(Function) });
    });
  });

  describe('trackInternalLoadEvents', () => {
    let querySelectorAllMock;
    let mockElements;
    const action = 'i_devops_action';

    beforeEach(() => {
      Tracker.enabled.mockReturnValue(true);
      querySelectorAllMock = jest.fn();
      document.querySelectorAll = querySelectorAllMock;
    });

    it('should return an empty array if Tracker is not enabled', () => {
      Tracker.enabled.mockReturnValue(false);
      const result = InternalEvents.trackInternalLoadEvents();
      expect(result).toEqual([]);
    });

    describe('tracking', () => {
      let trackEventSpy;
      beforeEach(() => {
        trackEventSpy = jest.spyOn(InternalEvents, 'track_event');
      });

      it('should track event if action exists', () => {
        mockElements = [{ dataset: { eventTracking: action, eventTrackingLoad: true } }];
        querySelectorAllMock.mockReturnValue(mockElements);

        const result = InternalEvents.trackInternalLoadEvents();
        expect(trackEventSpy).toHaveBeenCalledWith(action);
        expect(trackEventSpy).toHaveBeenCalledTimes(1);
        expect(querySelectorAllMock).toHaveBeenCalledWith(LOAD_INTERNAL_EVENTS_SELECTOR);
        expect(result).toEqual(mockElements);
      });

      it('should not track event if action is not present', () => {
        mockElements = [{ dataset: { eventTracking: undefined, eventTrackingLoad: true } }];
        querySelectorAllMock.mockReturnValue(mockElements);

        InternalEvents.trackInternalLoadEvents();
        expect(trackEventSpy).toHaveBeenCalledTimes(0);
      });
    });
  });
});
