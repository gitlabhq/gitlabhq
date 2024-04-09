import API from '~/api';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InternalEvents from '~/tracking/internal_events';
import { LOAD_INTERNAL_EVENTS_SELECTOR } from '~/tracking/constants';
import * as utils from '~/tracking/utils';
import { Tracker } from '~/tracking/tracker';
import Tracking from '~/tracking';

const allowedAdditionalProps = {
  property: 'value',
  label: 'value',
  value: 2,
};

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
    const category = 'TestCategory';

    it('trackEvent calls API.trackInternalEvent with correct arguments', () => {
      InternalEvents.trackEvent(event, {}, category);

      expect(API.trackInternalEvent).toHaveBeenCalledTimes(1);
      expect(API.trackInternalEvent).toHaveBeenCalledWith(event, {});
    });

    it('trackEvent calls Tracking.event with correct arguments including category', () => {
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      InternalEvents.trackEvent(event, {}, category);

      expect(Tracking.event).toHaveBeenCalledWith(category, event, expect.any(Object));
    });

    it('trackEvent calls Tracking.event with event name, category and additional properties', () => {
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      InternalEvents.trackEvent(event, allowedAdditionalProps, category);

      expect(Tracking.event).toHaveBeenCalledWith(
        category,
        event,
        expect.objectContaining({
          context: expect.any(Object),
          value: 2,
          property: 'value',
          label: 'value',
        }),
      );
    });

    it('trackEvent calls trackBrowserSDK with event name', () => {
      jest.spyOn(InternalEvents, 'trackBrowserSDK').mockImplementation(() => {});

      InternalEvents.trackEvent(event);

      expect(InternalEvents.trackBrowserSDK).toHaveBeenCalledTimes(1);
      expect(InternalEvents.trackBrowserSDK).toHaveBeenCalledWith(event, {});
    });

    it('trackEvent calls trackBrowserSDK with event name and additional Properties', () => {
      jest.spyOn(InternalEvents, 'trackBrowserSDK').mockImplementation(() => {});

      InternalEvents.trackEvent(event, allowedAdditionalProps);

      expect(InternalEvents.trackBrowserSDK).toHaveBeenCalledTimes(1);
      expect(InternalEvents.trackBrowserSDK).toHaveBeenCalledWith(event, {
        property: 'value',
        label: 'value',
        value: 2,
      });
    });

    it('throws an error if unallowed additionalProperties are passed', () => {
      jest.spyOn(InternalEvents, 'trackBrowserSDK').mockImplementation(() => {});
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      const additionalProps = {
        ...allowedAdditionalProps,
        unallowedKey: 'value',
      };

      expect(() => {
        InternalEvents.trackEvent(event, additionalProps, category);
      }).toThrow(/Disallowed additional properties were provided:/);

      expect(InternalEvents.trackBrowserSDK).not.toHaveBeenCalled();
      expect(Tracking.event).not.toHaveBeenCalled();
      expect(API.trackInternalEvent).not.toHaveBeenCalled();
    });
  });

  describe('mixin', () => {
    let wrapper;
    const Component = {
      template: `
    <div>
      <button data-testid="button" @click="handleButton1Click">Button</button>
      <button data-testid="button2" @click="handleButton2Click">Button2</button>
    </div>
  `,
      methods: {
        handleButton1Click() {
          this.trackEvent(event);
        },
        handleButton2Click() {
          this.trackEvent(event, {
            property: 'value',
            label: 'value',
            value: 2,
          });
        },
      },
      mixins: [InternalEvents.mixin()],
    };

    beforeEach(() => {
      wrapper = shallowMountExtended(Component);
    });

    it('this.trackEvent function calls InternalEvent`s track function with an event', async () => {
      const trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');

      await wrapper.findByTestId('button').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledTimes(1);
      expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
    });

    it('this.trackEvent function calls InternalEvent`s track function with an event and additional Properties', async () => {
      const trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');

      await wrapper.findByTestId('button2').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledTimes(1);
      expect(trackEventSpy).toHaveBeenCalledWith(
        event,
        {
          property: 'value',
          label: 'value',
          value: 2,
        },
        undefined,
      );
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
        expect(trackEventSpy).toHaveBeenCalledWith(action, {});
        expect(trackEventSpy).toHaveBeenCalledTimes(1);
        expect(querySelectorAllMock).toHaveBeenCalledWith(LOAD_INTERNAL_EVENTS_SELECTOR);
        expect(result).toEqual(mockElements);
      });

      it('should track event along with additional Properties if action exists', () => {
        mockElements = [
          {
            dataset: {
              eventTracking: action,
              eventTrackingLoad: true,
              eventProperty: 'test-property',
              eventLabel: 'test-label',
              eventValue: 2,
            },
          },
        ];
        querySelectorAllMock.mockReturnValue(mockElements);

        const result = InternalEvents.trackInternalLoadEvents();
        expect(trackEventSpy).toHaveBeenCalledWith(action, {
          label: 'test-label',
          property: 'test-property',
          value: 2,
        });
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

  describe('trackBrowserSDK', () => {
    beforeEach(() => {
      window.glClient = {
        track: jest.fn(),
      };
    });

    it('should not call glClient.track if Tracker is not enabled', () => {
      Tracker.enabled.mockReturnValue(false);

      InternalEvents.trackBrowserSDK(event);

      expect(window.glClient.track).not.toHaveBeenCalled();
    });

    it('should call glClient.track with event name if Tracker is enabled', () => {
      Tracker.enabled.mockReturnValue(true);

      InternalEvents.trackBrowserSDK(event);

      expect(window.glClient.track).toHaveBeenCalledTimes(1);
      expect(window.glClient.track).toHaveBeenCalledWith(event, {});
    });

    it('should call glClient.track with event name and additional properties if Tracker is enabled', () => {
      Tracker.enabled.mockReturnValue(true);

      InternalEvents.trackBrowserSDK(event, allowedAdditionalProps);

      expect(window.glClient.track).toHaveBeenCalledTimes(1);
      expect(window.glClient.track).toHaveBeenCalledWith(event, {
        property: 'value',
        label: 'value',
        value: 2,
      });
    });
  });
});
