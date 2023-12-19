import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import {
  init,
  clearEtagPoll,
  stopPolling,
  requestJob,
  fetchJob,
  receiveJobSuccess,
  receiveJobError,
  scrollTop,
  scrollBottom,
  requestJobLog,
  fetchJobLog,
  startPollingJobLog,
  stopPollingJobLog,
  receiveJobLogError,
  toggleCollapsibleLine,
  requestJobsForStage,
  fetchJobsForStage,
  receiveJobsForStageSuccess,
  receiveJobsForStageError,
  hideSidebar,
  showSidebar,
  toggleSidebar,
  receiveTestSummarySuccess,
  requestTestSummary,
  enterFullscreenSuccess,
  exitFullscreenSuccess,
  fullScreenContainerSetUpResult,
} from '~/ci/job_details/store/actions';
import { isScrolledToBottom } from '~/lib/utils/scroll_utils';

import * as types from '~/ci/job_details/store/mutation_types';
import state from '~/ci/job_details/store/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { testSummaryData } from 'jest/ci/jobs_mock_data';

jest.mock('~/lib/utils/scroll_utils');

const mockJobEndpoint = '/group1/project1/-/jobs/99.json';
const mockLogEndpoint = '/group1/project1/-/jobs/99/trace';

describe('Job State actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('init', () => {
    it('should commit SET_JOB_LOG_OPTIONS mutation', () => {
      return testAction(
        init,
        {
          jobEndpoint: mockJobEndpoint,
          logEndpoint: mockLogEndpoint,
          testReportSummaryUrl: '/group1/project1/-/jobs/99/test_report_summary.json',
        },
        mockedState,
        [
          {
            type: types.SET_JOB_LOG_OPTIONS,
            payload: {
              fullScreenAPIAvailable: false,
              jobEndpoint: mockJobEndpoint,
              logEndpoint: mockLogEndpoint,
              testReportSummaryUrl: '/group1/project1/-/jobs/99/test_report_summary.json',
            },
          },
        ],
        [{ type: 'fetchJob' }],
      );
    });
  });

  describe('hideSidebar', () => {
    it('should commit HIDE_SIDEBAR mutation', () => {
      return testAction(hideSidebar, null, mockedState, [{ type: types.HIDE_SIDEBAR }], []);
    });
  });

  describe('showSidebar', () => {
    it('should commit SHOW_SIDEBAR mutation', () => {
      return testAction(showSidebar, null, mockedState, [{ type: types.SHOW_SIDEBAR }], []);
    });
  });

  describe('toggleSidebar', () => {
    describe('when isSidebarOpen is true', () => {
      it('should dispatch hideSidebar', () => {
        return testAction(toggleSidebar, null, mockedState, [], [{ type: 'hideSidebar' }]);
      });
    });

    describe('when isSidebarOpen is false', () => {
      it('should dispatch showSidebar', () => {
        mockedState.isSidebarOpen = false;

        return testAction(toggleSidebar, null, mockedState, [], [{ type: 'showSidebar' }]);
      });
    });
  });

  describe('requestJob', () => {
    it('should commit REQUEST_JOB mutation', () => {
      return testAction(requestJob, null, mockedState, [{ type: types.REQUEST_JOB }], []);
    });
  });

  describe('fetchJob', () => {
    let mock;

    beforeEach(() => {
      mockedState.jobEndpoint = mockJobEndpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestJob and receiveJobSuccess', () => {
        mock.onGet(mockJobEndpoint).replyOnce(HTTP_STATUS_OK, { id: 121212, name: 'karma' });

        return testAction(
          fetchJob,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestJob',
            },
            {
              payload: { id: 121212, name: 'karma' },
              type: 'receiveJobSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches requestJob and receiveJobError', () => {
        return testAction(
          fetchJob,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestJob',
            },
            {
              type: 'receiveJobError',
            },
          ],
        );
      });
    });
  });

  describe('receiveJobSuccess', () => {
    it('should commit RECEIVE_JOB_SUCCESS mutation', () => {
      return testAction(
        receiveJobSuccess,
        { id: 121232132 },
        mockedState,
        [{ type: types.RECEIVE_JOB_SUCCESS, payload: { id: 121232132 } }],
        [],
      );
    });
  });

  describe('receiveJobError', () => {
    it('should commit RECEIVE_JOB_ERROR mutation', () => {
      return testAction(
        receiveJobError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOB_ERROR }],
        [],
      );
    });
  });

  describe('scrollTop', () => {
    it('should dispatch toggleScrollButtons action', () => {
      return testAction(scrollTop, null, mockedState, [], [{ type: 'toggleScrollButtons' }]);
    });
  });

  describe('scrollBottom', () => {
    it('should dispatch toggleScrollButtons action', () => {
      return testAction(scrollBottom, null, mockedState, [], [{ type: 'toggleScrollButtons' }]);
    });
  });

  describe('requestJobLog', () => {
    it('should commit REQUEST_JOB_LOG mutation', () => {
      return testAction(requestJobLog, null, mockedState, [{ type: types.REQUEST_JOB_LOG }], []);
    });
  });

  describe('fetchJobLog', () => {
    let mock;

    beforeEach(() => {
      mockedState.logEndpoint = mockLogEndpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      let jobLogPayload;

      beforeEach(() => {
        isScrolledToBottom.mockReturnValue(false);
      });

      describe('when job is complete', () => {
        beforeEach(() => {
          jobLogPayload = {
            html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
            complete: true,
          };

          mock.onGet(mockLogEndpoint).replyOnce(HTTP_STATUS_OK, jobLogPayload);
        });

        it('commits RECEIVE_JOB_LOG_SUCCESS, dispatches stopPollingJobLog and requestTestSummary', () => {
          return testAction(
            fetchJobLog,
            null,
            mockedState,
            [
              {
                type: types.RECEIVE_JOB_LOG_SUCCESS,
                payload: jobLogPayload,
              },
            ],
            [{ type: 'stopPollingJobLog' }, { type: 'requestTestSummary' }],
          );
        });
      });

      describe('when job is incomplete', () => {
        beforeEach(() => {
          jobLogPayload = {
            html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
            complete: false,
          };

          mock.onGet(mockLogEndpoint).replyOnce(HTTP_STATUS_OK, jobLogPayload);
        });

        it('dispatches startPollingJobLog', () => {
          return testAction(
            fetchJobLog,
            null,
            mockedState,
            [
              {
                type: types.RECEIVE_JOB_LOG_SUCCESS,
                payload: jobLogPayload,
              },
            ],
            [{ type: 'startPollingJobLog' }],
          );
        });

        it('does not dispatch startPollingJobLog when timeout is non-empty', () => {
          mockedState.jobLogTimeout = 1;

          return testAction(
            fetchJobLog,
            null,
            mockedState,
            [
              {
                type: types.RECEIVE_JOB_LOG_SUCCESS,
                payload: jobLogPayload,
              },
            ],
            [],
          );
        });
      });

      describe('when user scrolled to the bottom', () => {
        beforeEach(() => {
          isScrolledToBottom.mockReturnValue(true);

          jobLogPayload = {
            html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
            complete: true,
          };

          mock.onGet(mockLogEndpoint).replyOnce(HTTP_STATUS_OK, jobLogPayload);
        });

        it('should auto scroll to bottom by dispatching scrollBottom', () => {
          return testAction(
            fetchJobLog,
            null,
            mockedState,
            [
              {
                type: types.RECEIVE_JOB_LOG_SUCCESS,
                payload: jobLogPayload,
              },
            ],
            [
              { type: 'stopPollingJobLog' },
              { type: 'requestTestSummary' },
              { type: 'scrollBottom' },
            ],
          );
        });
      });
    });

    describe('server error', () => {
      beforeEach(() => {
        mock.onGet(mockLogEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches requestJobLog and receiveJobLogError', () => {
        return testAction(
          fetchJobLog,
          null,
          mockedState,
          [],
          [
            {
              type: 'receiveJobLogError',
            },
          ],
        );
      });
    });

    describe('unexpected error', () => {
      beforeEach(() => {
        mock.onGet(mockLogEndpoint).reply(() => {
          throw new Error('an error');
        });
      });

      it('dispatches requestJobLog and receiveJobLogError', () => {
        return testAction(
          fetchJobLog,
          null,
          mockedState,
          [],
          [
            {
              type: 'receiveJobLogError',
            },
          ],
        );
      });
    });
  });

  describe('startPollingJobLog', () => {
    let dispatch;
    let commit;

    beforeEach(() => {
      dispatch = jest.fn();
      commit = jest.fn();

      startPollingJobLog({ dispatch, commit });
    });

    afterEach(() => {
      jest.clearAllTimers();
    });

    it('should save the timeout id but not call fetchJobLog', () => {
      expect(commit).toHaveBeenCalledWith(types.SET_JOB_LOG_TIMEOUT, expect.any(Number));
      expect(commit.mock.calls[0][1]).toBeGreaterThan(0);

      expect(dispatch).not.toHaveBeenCalledWith('fetchJobLog');
    });

    describe('after timeout has passed', () => {
      beforeEach(() => {
        jest.advanceTimersByTime(4000);
      });

      it('should clear the timeout id and fetchJobLog', () => {
        expect(commit).toHaveBeenCalledWith(types.SET_JOB_LOG_TIMEOUT, 0);
        expect(dispatch).toHaveBeenCalledWith('fetchJobLog');
      });
    });
  });

  describe('stopPollingJobLog', () => {
    let origTimeout;

    beforeEach(() => {
      // Can't use spyOn(window, 'clearTimeout') because this caused unrelated specs to timeout
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23838#note_280277727
      origTimeout = window.clearTimeout;
      window.clearTimeout = jest.fn();
    });

    afterEach(() => {
      window.clearTimeout = origTimeout;
    });

    it('should commit STOP_POLLING_JOB_LOG mutation', async () => {
      const jobLogTimeout = 7;

      await testAction(
        stopPollingJobLog,
        null,
        { ...mockedState, jobLogTimeout },
        [{ type: types.SET_JOB_LOG_TIMEOUT, payload: 0 }, { type: types.STOP_POLLING_JOB_LOG }],
        [],
      );
      expect(window.clearTimeout).toHaveBeenCalledWith(jobLogTimeout);
    });
  });

  describe('receiveJobLogError', () => {
    it('should commit stop polling job log', () => {
      return testAction(receiveJobLogError, null, mockedState, [], [{ type: 'stopPollingJobLog' }]);
    });
  });

  describe('toggleCollapsibleLine', () => {
    it('should commit TOGGLE_COLLAPSIBLE_LINE mutation', () => {
      return testAction(
        toggleCollapsibleLine,
        { isClosed: true },
        mockedState,
        [{ type: types.TOGGLE_COLLAPSIBLE_LINE, payload: { isClosed: true } }],
        [],
      );
    });
  });

  describe('requestJobsForStage', () => {
    it('should commit REQUEST_JOBS_FOR_STAGE mutation', () => {
      return testAction(
        requestJobsForStage,
        { name: 'deploy' },
        mockedState,
        [{ type: types.REQUEST_JOBS_FOR_STAGE, payload: { name: 'deploy' } }],
        [],
      );
    });
  });

  describe('fetchJobsForStage', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestJobsForStage and receiveJobsForStageSuccess', () => {
        mock.onGet(`${TEST_HOST}/jobs.json`).replyOnce(HTTP_STATUS_OK, {
          latest_statuses: [{ id: 121212, name: 'build' }],
          retried: [],
        });

        return testAction(
          fetchJobsForStage,
          { dropdown_path: `${TEST_HOST}/jobs.json` },
          mockedState,
          [],
          [
            {
              type: 'requestJobsForStage',
              payload: { dropdown_path: `${TEST_HOST}/jobs.json` },
            },
            {
              payload: [{ id: 121212, name: 'build' }],
              type: 'receiveJobsForStageSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/jobs.json`).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches requestJobsForStage and receiveJobsForStageError', () => {
        return testAction(
          fetchJobsForStage,
          { dropdown_path: `${TEST_HOST}/jobs.json` },
          mockedState,
          [],
          [
            {
              type: 'requestJobsForStage',
              payload: { dropdown_path: `${TEST_HOST}/jobs.json` },
            },
            {
              type: 'receiveJobsForStageError',
            },
          ],
        );
      });
    });
  });

  describe('receiveJobsForStageSuccess', () => {
    it('should commit RECEIVE_JOBS_FOR_STAGE_SUCCESS mutation', () => {
      return testAction(
        receiveJobsForStageSuccess,
        [{ id: 121212, name: 'karma' }],
        mockedState,
        [{ type: types.RECEIVE_JOBS_FOR_STAGE_SUCCESS, payload: [{ id: 121212, name: 'karma' }] }],
        [],
      );
    });
  });

  describe('receiveJobsForStageError', () => {
    it('should commit RECEIVE_JOBS_FOR_STAGE_ERROR mutation', () => {
      return testAction(
        receiveJobsForStageError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOBS_FOR_STAGE_ERROR }],
        [],
      );
    });
  });

  describe('requestTestSummarySuccess', () => {
    it('should commit RECEIVE_TEST_SUMMARY_SUCCESS mutation', () => {
      return testAction(
        receiveTestSummarySuccess,
        { total: {}, test_suites: [] },
        mockedState,
        [{ type: types.RECEIVE_TEST_SUMMARY_SUCCESS, payload: { total: {}, test_suites: [] } }],
        [],
      );
    });
  });

  describe('requestTestSummary', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches receiveTestSummarySuccess', () => {
        mockedState.testReportSummaryUrl = `${TEST_HOST}/test_report_summary.json`;

        mock
          .onGet(`${TEST_HOST}/test_report_summary.json`)
          .replyOnce(HTTP_STATUS_OK, testSummaryData);

        return testAction(
          requestTestSummary,
          null,
          mockedState,
          [{ type: types.RECEIVE_TEST_SUMMARY_COMPLETE }],
          [
            {
              payload: testSummaryData,
              type: 'receiveTestSummarySuccess',
            },
          ],
        );
      });
    });

    describe('without testReportSummaryUrl', () => {
      it('does not dispatch any actions or mutations', () => {
        return testAction(requestTestSummary, null, mockedState, [], []);
      });
    });
  });

  describe('enterFullscreenSuccess', () => {
    it('should commit ENTER_FULLSCREEN_SUCCESS mutation', () => {
      return testAction(
        enterFullscreenSuccess,
        {},
        mockedState,
        [{ type: types.ENTER_FULLSCREEN_SUCCESS }],
        [],
      );
    });
  });

  describe('exitFullscreenSuccess', () => {
    it('should commit EXIT_FULLSCREEN_SUCCESS mutation', () => {
      return testAction(
        exitFullscreenSuccess,
        {},
        mockedState,
        [{ type: types.EXIT_FULLSCREEN_SUCCESS }],
        [],
      );
    });
  });

  describe('fullScreenContainerSetUpResult', () => {
    it('should commit FULL_SCREEN_CONTAINER_SET_UP mutation', () => {
      return testAction(
        fullScreenContainerSetUpResult,
        {},
        mockedState,
        [{ type: types.FULL_SCREEN_CONTAINER_SET_UP, payload: {} }],
        [],
      );
    });
  });
});
