import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData, getAllExperimentContexts } from '~/experimentation/utils';
import Tracking, { initUserTracking, initDefaultTrackers, InternalEvents } from '~/tracking';
import { MAX_LOCAL_STORAGE_QUEUE_SIZE } from '~/tracking/constants';
import getStandardContext from '~/tracking/get_standard_context';

jest.mock('~/experimentation/utils', () => ({
  getExperimentData: jest.fn(),
  getAllExperimentContexts: jest.fn(),
}));

describe('Tracking', () => {
  let standardContext;
  let snowplowSpy;
  let bindDocumentSpy;
  let trackLoadEventsSpy;
  let enableFormTracking;
  let setAnonymousUrlsSpy;
  let bindInternalEventDocumentSpy;
  let trackInternalLoadEventsSpy;
  let initBrowserSDKSpy;

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
    getAllExperimentContexts.mockReturnValue([]);

    window.snowplow = window.snowplow || (() => {});
    window.snowplowOptions = {
      namespace: 'gl_test',
      hostname: 'app.test.com',
      cookieDomain: '.test.com',
    };

    snowplowSpy = jest.spyOn(window, 'snowplow');
  });

  describe('initUserTracking', () => {
    it('calls through to get a new tracker with the expected options', () => {
      initUserTracking();
      expect(snowplowSpy).toHaveBeenCalledWith('newTracker', 'gl_test', 'app.test.com', {
        namespace: 'gl_test',
        hostname: 'app.test.com',
        cookieDomain: '.test.com',
        appId: '',
        respectDoNotTrack: true,
        eventMethod: 'post',
        plugins: [],
        contexts: { webPage: true, performanceTiming: true },
        formTracking: false,
        linkClickTracking: false,
        formTrackingConfig: {
          fields: { allow: [] },
          forms: { allow: [] },
        },
        maxLocalStorageQueueSize: MAX_LOCAL_STORAGE_QUEUE_SIZE,
      });
    });

    it('does not initialize tracking if not enabled', () => {
      jest.spyOn(Tracking, 'enabled').mockReturnValue(false);

      initUserTracking();

      expect(snowplowSpy).not.toHaveBeenCalled();
    });

    it('dispatches SnowplowInitialized event after initializing', () => {
      const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

      initUserTracking();

      expect(dispatchEventSpy).toHaveBeenCalledWith(new Event('SnowplowInitialized'));
    });
  });

  describe('initDefaultTrackers', () => {
    beforeEach(() => {
      bindDocumentSpy = jest.spyOn(Tracking, 'bindDocument').mockImplementation(() => null);
      trackLoadEventsSpy = jest.spyOn(Tracking, 'trackLoadEvents').mockImplementation(() => null);
      enableFormTracking = jest
        .spyOn(Tracking, 'enableFormTracking')
        .mockImplementation(() => null);
      setAnonymousUrlsSpy = jest.spyOn(Tracking, 'setAnonymousUrls').mockImplementation(() => null);
      bindInternalEventDocumentSpy = jest
        .spyOn(InternalEvents, 'bindInternalEventDocument')
        .mockImplementation(() => null);
      trackInternalLoadEventsSpy = jest
        .spyOn(InternalEvents, 'trackInternalLoadEvents')
        .mockImplementation(() => null);
      initBrowserSDKSpy = jest
        .spyOn(InternalEvents, 'initBrowserSDK')
        .mockImplementation(() => null);
    });

    it('should activate features based on what has been enabled', () => {
      initDefaultTrackers();
      expect(snowplowSpy).toHaveBeenCalledWith('enableActivityTracking', {
        minimumVisitLength: 30,
        heartbeatDelay: 30,
      });
      expect(snowplowSpy).toHaveBeenCalledWith('trackPageView', {
        title: 'GitLab',
        context: [standardContext],
      });
      expect(snowplowSpy).toHaveBeenCalledWith('setDocumentTitle', 'GitLab');
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

    it('calls the anonymized URLs method', () => {
      initDefaultTrackers();
      expect(setAnonymousUrlsSpy).toHaveBeenCalled();
    });

    it('binds the document event handling for intenral events', () => {
      initDefaultTrackers();
      expect(bindInternalEventDocumentSpy).toHaveBeenCalled();
    });

    it('tracks page loaded events for internal events', () => {
      initDefaultTrackers();
      expect(trackInternalLoadEventsSpy).toHaveBeenCalled();
    });

    it('calls initBrowserSDKSpy', () => {
      initDefaultTrackers();
      expect(initBrowserSDKSpy).toHaveBeenCalled();
    });

    describe('when there are experiment contexts', () => {
      const experimentContexts = [
        {
          schema: TRACKING_CONTEXT_SCHEMA,
          data: { experiment: 'experiment1', variant: 'control' },
        },
        {
          schema: TRACKING_CONTEXT_SCHEMA,
          data: { experiment: 'experiment_two', variant: 'candidate' },
        },
      ];

      beforeEach(() => {
        getAllExperimentContexts.mockReturnValue(experimentContexts);
      });

      it('includes those contexts alongside the standard context', () => {
        initDefaultTrackers();
        expect(snowplowSpy).toHaveBeenCalledWith('trackPageView', {
          title: 'GitLab',
          context: [standardContext, ...experimentContexts],
        });
      });
    });

    it('does not initialize default trackers if not enabled', () => {
      jest.spyOn(Tracking, 'enabled').mockReturnValue(false);

      initDefaultTrackers();

      expect(snowplowSpy).not.toHaveBeenCalled();
      expect(bindDocumentSpy).not.toHaveBeenCalled();
      expect(trackLoadEventsSpy).not.toHaveBeenCalled();
      expect(enableFormTracking).not.toHaveBeenCalled();
      expect(setAnonymousUrlsSpy).not.toHaveBeenCalled();
      expect(bindInternalEventDocumentSpy).not.toHaveBeenCalled();
      expect(trackInternalLoadEventsSpy).not.toHaveBeenCalled();
      expect(initBrowserSDKSpy).not.toHaveBeenCalled();
    });

    it('flushes pending events before other tracking methods', () => {
      const flushPendingEventsSpy = jest.spyOn(Tracking, 'flushPendingEvents').mockImplementation();

      initDefaultTrackers();

      expect(flushPendingEventsSpy.mock.invocationCallOrder[0]).toBeLessThan(
        bindDocumentSpy.mock.invocationCallOrder[0],
      );
      expect(flushPendingEventsSpy.mock.invocationCallOrder[0]).toBeLessThan(
        trackLoadEventsSpy.mock.invocationCallOrder[0],
      );
      expect(flushPendingEventsSpy.mock.invocationCallOrder[0]).toBeLessThan(
        bindInternalEventDocumentSpy.mock.invocationCallOrder[0],
      );
      expect(flushPendingEventsSpy.mock.invocationCallOrder[0]).toBeLessThan(
        trackInternalLoadEventsSpy.mock.invocationCallOrder[0],
      );
      expect(flushPendingEventsSpy.mock.invocationCallOrder[0]).toBeLessThan(
        initBrowserSDKSpy.mock.invocationCallOrder[0],
      );
    });

    it('calls setAnonymousUrls before initializing trackers', () => {
      initDefaultTrackers();

      expect(setAnonymousUrlsSpy.mock.invocationCallOrder[0]).toBeLessThan(
        snowplowSpy.mock.invocationCallOrder[0],
      );
    });
  });
});
