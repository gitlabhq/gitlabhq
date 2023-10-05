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
import { extraContext } from './mock_data';

jest.mock('~/api', () => ({
  trackInternalEvent: jest.fn(),
}));

jest.mock('~/tracking/utils', () => ({
  ...jest.requireActual('~/tracking/utils'),
  getInternalEventHandlers: jest.fn(),
}));

Tracker.enabled = jest.fn();

const event = 'TestEvent';

describe('InternalEvents', () => {
  describe('trackEvent', () => {
    it('trackEvent calls API.trackInternalEvent with correct arguments', () => {
      InternalEvents.trackEvent(event);

      expect(API.trackInternalEvent).toHaveBeenCalledTimes(1);
      expect(API.trackInternalEvent).toHaveBeenCalledWith(event);
    });

    it('trackEvent calls tracking.event functions with correct arguments', () => {
      const trackingSpy = mockTracking(GITLAB_INTERNAL_EVENT_CATEGORY, undefined, jest.spyOn);

      InternalEvents.trackEvent(event, { context: extraContext });

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(GITLAB_INTERNAL_EVENT_CATEGORY, event, {
        context: [
          {
            schema: SERVICE_PING_SCHEMA,
            data: {
              event_name: event,
              data_source: 'redis_hll',
            },
          },
          extraContext,
        ],
      });
    });
  });

  describe('mixin', () => {
    let wrapper;
    const Component = {
      template: `
    <div>
      <button data-testid="button1" @click="handleButton1Click">Button 1</button>
      <button data-testid="button2" @click="handleButton2Click">Button 2</button>
    </div>
  `,
      methods: {
        handleButton1Click() {
          this.trackEvent(event);
        },
        handleButton2Click() {
          this.trackEvent(event, extraContext);
        },
      },
      mixins: [InternalEvents.mixin()],
    };

    beforeEach(() => {
      wrapper = shallowMountExtended(Component);
    });

    it('this.trackEvent function calls InternalEvent`s track function with an event', async () => {
      const trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');

      await wrapper.findByTestId('button1').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledTimes(1);
      expect(trackEventSpy).toHaveBeenCalledWith(event, {});
    });

    it("this.trackEvent function calls InternalEvent's track function with an event and data", async () => {
      const data = extraContext;
      const trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');

      await wrapper.findByTestId('button2').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledTimes(1);
      expect(trackEventSpy).toHaveBeenCalledWith(event, data);
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
        trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');
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

  describe('initBrowserSDK', () => {
    beforeEach(() => {
      window.glClient = {
        setDocumentTitle: jest.fn(),
        page: jest.fn(),
      };
      window.gl = {
        environment: 'testing',
        key: 'value',
      };
    });

    it('should not call setDocumentTitle or page methods when window.glClient is undefined', () => {
      window.glClient = undefined;

      InternalEvents.initBrowserSDK();

      expect(window.glClient?.setDocumentTitle).toBeUndefined();
      expect(window.glClient?.page).toBeUndefined();
    });

    it('should call setDocumentTitle and page methods on window.glClient when it is defined', () => {
      InternalEvents.initBrowserSDK();

      expect(window.glClient.setDocumentTitle).toHaveBeenCalledWith('GitLab');
      expect(window.glClient.page).toHaveBeenCalledWith({
        title: 'GitLab',
      });
    });

    it('should call setDocumentTitle and page methods with default data when window.gl is undefined', () => {
      window.gl = undefined;

      InternalEvents.initBrowserSDK();

      expect(window.glClient.setDocumentTitle).toHaveBeenCalledWith('GitLab');
      expect(window.glClient.page).toHaveBeenCalledWith({
        title: 'GitLab',
      });
    });
  });
});
