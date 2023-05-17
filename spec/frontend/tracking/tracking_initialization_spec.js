import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData, getAllExperimentContexts } from '~/experimentation/utils';
import Tracking, { initUserTracking, initDefaultTrackers } from '~/tracking';
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
      setAnonymousUrlsSpy = jest.spyOn(Tracking, 'setAnonymousUrls').mockImplementation(() => null);
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
  });
});
