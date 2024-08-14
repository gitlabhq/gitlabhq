import API from '~/api';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InternalEvents from '~/tracking/internal_events';
import { LOAD_INTERNAL_EVENTS_SELECTOR } from '~/tracking/constants';
import * as utils from '~/tracking/utils';
import { Tracker } from '~/tracking/tracker';
import Tracking from '~/tracking';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';

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
  beforeEach(() => {
    setHTMLFixture(`<div><button data-event-tracking data-testid="button" /></div>`);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findButton = () => document.querySelector('[data-testid="button"]');
  const triggerClick = () => {
    findButton().dispatchEvent(new Event('click', { bubbles: true }));
  };

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

    it('trackEvent calls Tracking.event with event name, category, base and custom properties', () => {
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      const additionalProps = {
        ...allowedAdditionalProps,
        key: 'value',
      };

      InternalEvents.trackEvent(event, additionalProps, category);

      expect(Tracking.event).toHaveBeenCalledWith(
        category,
        event,
        expect.objectContaining({
          context: expect.any(Object),
          value: 2,
          property: 'value',
          label: 'value',
          extra: { key: 'value' },
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

    it('throws an error if base property has incorrect type', () => {
      jest.spyOn(InternalEvents, 'trackBrowserSDK').mockImplementation(() => {});
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      const additionalProps = {
        ...allowedAdditionalProps,
        value: 'invalidType',
      };

      expect(() => {
        InternalEvents.trackEvent(event, additionalProps, category);
      }).toThrow('value should be of type: number. Provided type is: string.');

      expect(InternalEvents.trackBrowserSDK).not.toHaveBeenCalled();
      expect(Tracking.event).not.toHaveBeenCalled();
      expect(API.trackInternalEvent).not.toHaveBeenCalled();
    });

    it('does not throw an error for custom properties', () => {
      jest.spyOn(InternalEvents, 'trackBrowserSDK').mockImplementation(() => {});
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      const additionalProps = {
        ...allowedAdditionalProps,
        key1: 'value1',
        key2: 2,
      };

      expect(() => {
        InternalEvents.trackEvent(event, additionalProps, category);
      }).not.toThrow();

      expect(InternalEvents.trackBrowserSDK).toHaveBeenCalled();
      expect(Tracking.event).toHaveBeenCalled();
      expect(API.trackInternalEvent).toHaveBeenCalled();
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
    let disposeBind;
    let trackEventSpy;

    beforeEach(() => {
      Tracker.enabled.mockReturnValue(true);
      trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');
    });

    afterEach(() => {
      disposeBind?.();
    });

    it('should not bind event handlers if tracker is not enabled', () => {
      Tracker.enabled.mockReturnValue(false);

      disposeBind = InternalEvents.bindInternalEventDocument();

      expect(disposeBind).toBe(null);
      expect(utils.getInternalEventHandlers).not.toHaveBeenCalled();
    });

    it('should not bind event handlers if already bound', () => {
      disposeBind = InternalEvents.bindInternalEventDocument();

      utils.getInternalEventHandlers.mockReset();

      const nextDisposeBind = InternalEvents.bindInternalEventDocument();

      expect(nextDisposeBind).toBe(null);
      expect(utils.getInternalEventHandlers).not.toHaveBeenCalled();
    });

    it('should bind event handlers when not bound yet', () => {
      disposeBind = InternalEvents.bindInternalEventDocument();

      triggerClick();

      expect(trackEventSpy).toHaveBeenCalledWith('', {});
    });

    it('returns function that disposes listener', () => {
      disposeBind = InternalEvents.bindInternalEventDocument();
      disposeBind();

      triggerClick();

      expect(trackEventSpy).not.toHaveBeenCalled();
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
      window.glClient = { track: jest.fn() };
      Tracker.enabled = jest.fn();
    });

    afterEach(() => {
      window.glClient = null;
      window.gl = null;
    });

    const mockSnowplowContext = (projectId, namespaceId) => {
      window.gl = {
        snowplowStandardContext: {
          data: { project_id: projectId, namespace_id: namespaceId },
        },
      };
    };

    it('should not call glClient.track if Tracker is not enabled', () => {
      Tracker.enabled.mockReturnValue(false);

      InternalEvents.trackBrowserSDK(event);

      expect(window.glClient.track).not.toHaveBeenCalled();
    });

    it('should call glClient.track with event name if Tracker is enabled and no project_id and namespace_id present', () => {
      mockSnowplowContext(null, null);
      Tracker.enabled.mockReturnValue(true);

      InternalEvents.trackBrowserSDK(event);

      expect(window.glClient.track).toHaveBeenCalledTimes(1);
      expect(window.glClient.track).toHaveBeenCalledWith(event, {
        project_id: null,
        namespace_id: null,
      });
    });

    it('should call glClient.track with event name and additional properties if Tracker is enabled', () => {
      mockSnowplowContext(123, 456);
      Tracker.enabled.mockReturnValue(true);

      InternalEvents.trackBrowserSDK(event, allowedAdditionalProps);

      expect(window.glClient.track).toHaveBeenCalledTimes(1);
      expect(window.glClient.track).toHaveBeenCalledWith(event, {
        project_id: 123,
        namespace_id: 456,
        ...allowedAdditionalProps,
      });
    });
  });
});
