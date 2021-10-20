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

describe('Job State actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setJobEndpoint', () => {
    it('should commit SET_JOB_ENDPOINT mutation', (done) => {
      testAction(
        setJobEndpoint,
        'job/872324.json',
        mockedState,
        [{ type: types.SET_JOB_ENDPOINT, payload: 'job/872324.json' }],
        [],
        done,
      );
    });
  });

  describe('setJobLogOptions', () => {
    it('should commit SET_JOB_LOG_OPTIONS mutation', (done) => {
      testAction(
        setJobLogOptions,
        { pagePath: 'job/872324/trace.json' },
        mockedState,
        [{ type: types.SET_JOB_LOG_OPTIONS, payload: { pagePath: 'job/872324/trace.json' } }],
        [],
        done,
      );
    });
  });

  describe('hideSidebar', () => {
    it('should commit HIDE_SIDEBAR mutation', (done) => {
      testAction(hideSidebar, null, mockedState, [{ type: types.HIDE_SIDEBAR }], [], done);
    });
  });

  describe('showSidebar', () => {
    it('should commit HIDE_SIDEBAR mutation', (done) => {
      testAction(showSidebar, null, mockedState, [{ type: types.SHOW_SIDEBAR }], [], done);
    });
  });

  describe('toggleSidebar', () => {
    describe('when isSidebarOpen is true', () => {
      it('should dispatch hideSidebar', (done) => {
        testAction(toggleSidebar, null, mockedState, [], [{ type: 'hideSidebar' }], done);
      });
    });

    describe('when isSidebarOpen is false', () => {
      it('should dispatch showSidebar', (done) => {
        mockedState.isSidebarOpen = false;

        testAction(toggleSidebar, null, mockedState, [], [{ type: 'showSidebar' }], done);
      });
    });
  });

  describe('requestJob', () => {
    it('should commit REQUEST_JOB mutation', (done) => {
      testAction(requestJob, null, mockedState, [{ type: types.REQUEST_JOB }], [], done);
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
      it('dispatches requestJob and receiveJobSuccess ', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, { id: 121212, name: 'karma' });

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches requestJob and receiveJobError ', (done) => {
        testAction(
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
          done,
        );
      });
    });
  });

  describe('receiveJobSuccess', () => {
    it('should commit RECEIVE_JOB_SUCCESS mutation', (done) => {
      testAction(
        receiveJobSuccess,
        { id: 121232132 },
        mockedState,
        [{ type: types.RECEIVE_JOB_SUCCESS, payload: { id: 121232132 } }],
        [],
        done,
      );
    });
  });

  describe('receiveJobError', () => {
    it('should commit RECEIVE_JOB_ERROR mutation', (done) => {
      testAction(receiveJobError, null, mockedState, [{ type: types.RECEIVE_JOB_ERROR }], [], done);
    });
  });

  describe('scrollTop', () => {
    it('should dispatch toggleScrollButtons action', (done) => {
      testAction(scrollTop, null, mockedState, [], [{ type: 'toggleScrollButtons' }], done);
    });
  });

  describe('scrollBottom', () => {
    it('should dispatch toggleScrollButtons action', (done) => {
      testAction(scrollBottom, null, mockedState, [], [{ type: 'toggleScrollButtons' }], done);
    });
  });

  describe('requestJobLog', () => {
    it('should commit REQUEST_JOB_LOG mutation', (done) => {
      testAction(requestJobLog, null, mockedState, [{ type: types.REQUEST_JOB_LOG }], [], done);
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
      it('dispatches requestJobLog, receiveJobLogSuccess and stopPollingJobLog when job is complete', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint/trace.json`).replyOnce(200, {
          html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
          complete: true,
        });

        testAction(
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
          done,
        );
      });

      describe('when job is incomplete', () => {
        let jobLogPayload;

        beforeEach(() => {
          jobLogPayload = {
            html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
            complete: false,
          };

          mock.onGet(`${TEST_HOST}/endpoint/trace.json`).replyOnce(200, jobLogPayload);
        });

        it('dispatches startPollingJobLog', (done) => {
          testAction(
            fetchJobLog,
            null,
            mockedState,
            [],
            [
              { type: 'toggleScrollisInBottom', payload: true },
              { type: 'receiveJobLogSuccess', payload: jobLogPayload },
              { type: 'startPollingJobLog' },
            ],
            done,
          );
        });

        it('does not dispatch startPollingJobLog when timeout is non-empty', (done) => {
          mockedState.jobLogTimeout = 1;

          testAction(
            fetchJobLog,
            null,
            mockedState,
            [],
            [
              { type: 'toggleScrollisInBottom', payload: true },
              { type: 'receiveJobLogSuccess', payload: jobLogPayload },
            ],
            done,
          );
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint/trace.json`).reply(500);
      });

      it('dispatches requestJobLog and receiveJobLogError ', (done) => {
        testAction(
          fetchJobLog,
          null,
          mockedState,
          [],
          [
            {
              type: 'receiveJobLogError',
            },
          ],
          done,
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

    it('should commit STOP_POLLING_JOB_LOG mutation ', (done) => {
      const jobLogTimeout = 7;

      testAction(
        stopPollingJobLog,
        null,
        { ...mockedState, jobLogTimeout },
        [{ type: types.SET_JOB_LOG_TIMEOUT, payload: 0 }, { type: types.STOP_POLLING_JOB_LOG }],
        [],
      )
        .then(() => {
          expect(window.clearTimeout).toHaveBeenCalledWith(jobLogTimeout);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveJobLogSuccess', () => {
    it('should commit RECEIVE_JOB_LOG_SUCCESS mutation ', (done) => {
      testAction(
        receiveJobLogSuccess,
        'hello world',
        mockedState,
        [{ type: types.RECEIVE_JOB_LOG_SUCCESS, payload: 'hello world' }],
        [],
        done,
      );
    });
  });

  describe('receiveJobLogError', () => {
    it('should commit stop polling job log', (done) => {
      testAction(receiveJobLogError, null, mockedState, [], [{ type: 'stopPollingJobLog' }], done);
    });
  });

  describe('toggleCollapsibleLine', () => {
    it('should commit TOGGLE_COLLAPSIBLE_LINE mutation ', (done) => {
      testAction(
        toggleCollapsibleLine,
        { isClosed: true },
        mockedState,
        [{ type: types.TOGGLE_COLLAPSIBLE_LINE, payload: { isClosed: true } }],
        [],
        done,
      );
    });
  });

  describe('requestJobsForStage', () => {
    it('should commit REQUEST_JOBS_FOR_STAGE mutation ', (done) => {
      testAction(
        requestJobsForStage,
        { name: 'deploy' },
        mockedState,
        [{ type: types.REQUEST_JOBS_FOR_STAGE, payload: { name: 'deploy' } }],
        [],
        done,
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
      it('dispatches requestJobsForStage and receiveJobsForStageSuccess ', (done) => {
        mock
          .onGet(`${TEST_HOST}/jobs.json`)
          .replyOnce(200, { latest_statuses: [{ id: 121212, name: 'build' }], retried: [] });

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/jobs.json`).reply(500);
      });

      it('dispatches requestJobsForStage and receiveJobsForStageError', (done) => {
        testAction(
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
          done,
        );
      });
    });
  });

  describe('receiveJobsForStageSuccess', () => {
    it('should commit RECEIVE_JOBS_FOR_STAGE_SUCCESS mutation ', (done) => {
      testAction(
        receiveJobsForStageSuccess,
        [{ id: 121212, name: 'karma' }],
        mockedState,
        [{ type: types.RECEIVE_JOBS_FOR_STAGE_SUCCESS, payload: [{ id: 121212, name: 'karma' }] }],
        [],
        done,
      );
    });
  });

  describe('receiveJobsForStageError', () => {
    it('should commit RECEIVE_JOBS_FOR_STAGE_ERROR mutation ', (done) => {
      testAction(
        receiveJobsForStageError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOBS_FOR_STAGE_ERROR }],
        [],
        done,
      );
    });
  });
});
