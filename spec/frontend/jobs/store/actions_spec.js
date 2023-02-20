import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import {
  setJobEndpoint,
  setJobLogOptions,
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
  receiveJobLogSuccess,
  receiveJobLogError,
  toggleCollapsibleLine,
  requestJobsForStage,
  fetchJobsForStage,
  receiveJobsForStageSuccess,
  receiveJobsForStageError,
  hideSidebar,
  showSidebar,
  toggleSidebar,
} from '~/jobs/store/actions';
import * as types from '~/jobs/store/mutation_types';
import state from '~/jobs/store/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Job State actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setJobEndpoint', () => {
    it('should commit SET_JOB_ENDPOINT mutation', () => {
      return testAction(
        setJobEndpoint,
        'job/872324.json',
        mockedState,
        [{ type: types.SET_JOB_ENDPOINT, payload: 'job/872324.json' }],
        [],
      );
    });
  });

  describe('setJobLogOptions', () => {
    it('should commit SET_JOB_LOG_OPTIONS mutation', () => {
      return testAction(
        setJobLogOptions,
        { pagePath: 'job/872324/trace.json' },
        mockedState,
        [{ type: types.SET_JOB_LOG_OPTIONS, payload: { pagePath: 'job/872324/trace.json' } }],
        [],
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
      mockedState.jobEndpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestJob and receiveJobSuccess', () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`)
          .replyOnce(HTTP_STATUS_OK, { id: 121212, name: 'karma' });

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
      mockedState.jobLogEndpoint = `${TEST_HOST}/endpoint`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestJobLog, receiveJobLogSuccess and stopPollingJobLog when job is complete', () => {
        mock.onGet(`${TEST_HOST}/endpoint/trace.json`).replyOnce(HTTP_STATUS_OK, {
          html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
          complete: true,
        });

        return testAction(
          fetchJobLog,
          null,
          mockedState,
          [],
          [
            {
              type: 'toggleScrollisInBottom',
              payload: true,
            },
            {
              payload: {
                html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
                complete: true,
              },
              type: 'receiveJobLogSuccess',
            },
            {
              type: 'stopPollingJobLog',
            },
          ],
        );
      });

      describe('when job is incomplete', () => {
        let jobLogPayload;

        beforeEach(() => {
          jobLogPayload = {
            html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
            complete: false,
          };

          mock.onGet(`${TEST_HOST}/endpoint/trace.json`).replyOnce(HTTP_STATUS_OK, jobLogPayload);
        });

        it('dispatches startPollingJobLog', () => {
          return testAction(
            fetchJobLog,
            null,
            mockedState,
            [],
            [
              { type: 'toggleScrollisInBottom', payload: true },
              { type: 'receiveJobLogSuccess', payload: jobLogPayload },
              { type: 'startPollingJobLog' },
            ],
          );
        });

        it('does not dispatch startPollingJobLog when timeout is non-empty', () => {
          mockedState.jobLogTimeout = 1;

          return testAction(
            fetchJobLog,
            null,
            mockedState,
            [],
            [
              { type: 'toggleScrollisInBottom', payload: true },
              { type: 'receiveJobLogSuccess', payload: jobLogPayload },
            ],
          );
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint/trace.json`).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
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

  describe('receiveJobLogSuccess', () => {
    it('should commit RECEIVE_JOB_LOG_SUCCESS mutation', () => {
      return testAction(
        receiveJobLogSuccess,
        'hello world',
        mockedState,
        [{ type: types.RECEIVE_JOB_LOG_SUCCESS, payload: 'hello world' }],
        [],
      );
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
});
