import Visibility from 'visibilityjs';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import {
  requestLatestPipeline,
  receiveLatestPipelineError,
  receiveLatestPipelineSuccess,
  fetchLatestPipeline,
  stopPipelinePolling,
  clearEtagPoll,
  requestJobs,
  receiveJobsError,
  receiveJobsSuccess,
  fetchJobs,
  toggleStageCollapsed,
  setDetailJob,
  requestJobTrace,
  receiveJobTraceError,
  receiveJobTraceSuccess,
  fetchJobTrace,
  resetLatestPipeline,
} from '~/ide/stores/modules/pipelines/actions';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import { rightSidebarViews } from '~/ide/constants';
import testAction from '../../../../helpers/vuex_action_helper';
import { pipelines, jobs } from '../../../mock_data';

describe('IDE pipelines actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);

    gon.api_version = 'v4';
    mockedState.currentProjectId = 'test/project';
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestLatestPipeline', () => {
    it('commits request', done => {
      testAction(
        requestLatestPipeline,
        null,
        mockedState,
        [{ type: types.REQUEST_LATEST_PIPELINE }],
        [],
        done,
      );
    });
  });

  describe('receiveLatestPipelineError', () => {
    it('commits error', done => {
      testAction(
        receiveLatestPipelineError,
        { status: 404 },
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_ERROR }],
        [{ type: 'stopPipelinePolling' }],
        done,
      );
    });

    it('dispatches setErrorMessage is not 404', done => {
      testAction(
        receiveLatestPipelineError,
        { status: 500 },
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'An error occurred whilst fetching the latest pipeline.',
              action: expect.any(Function),
              actionText: 'Please try again',
              actionPayload: null,
            },
          },
          { type: 'stopPipelinePolling' },
        ],
        done,
      );
    });
  });

  describe('receiveLatestPipelineSuccess', () => {
    const rootGetters = { lastCommit: { id: '123' } };
    let commit;

    beforeEach(() => {
      commit = jest.fn().mockName('commit');
    });

    it('commits pipeline', () => {
      receiveLatestPipelineSuccess({ rootGetters, commit }, { pipelines });
      expect(commit).toHaveBeenCalledWith(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, pipelines[0]);
    });

    it('commits false when there are no pipelines', () => {
      receiveLatestPipelineSuccess({ rootGetters, commit }, { pipelines: [] });
      expect(commit).toHaveBeenCalledWith(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, false);
    });
  });

  describe('fetchLatestPipeline', () => {
    afterEach(() => {
      stopPipelinePolling();
      clearEtagPoll();
    });

    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet('/abc/def/commit/abc123def456ghi789jkl/pipelines')
          .reply(200, { data: { foo: 'bar' } }, { 'poll-interval': '10000' });
      });

      it('dispatches request', done => {
        jest.spyOn(axios, 'get');
        jest.spyOn(Visibility, 'hidden').mockReturnValue(false);

        const dispatch = jest.fn().mockName('dispatch');
        const rootGetters = {
          lastCommit: { id: 'abc123def456ghi789jkl' },
          currentProject: { path_with_namespace: 'abc/def' },
        };

        fetchLatestPipeline({ dispatch, rootGetters });

        expect(dispatch).toHaveBeenCalledWith('requestLatestPipeline');

        jest.advanceTimersByTime(1000);

        new Promise(resolve => requestAnimationFrame(resolve))
          .then(() => {
            expect(axios.get).toHaveBeenCalled();
            expect(axios.get).toHaveBeenCalledTimes(1);
            expect(dispatch).toHaveBeenCalledWith(
              'receiveLatestPipelineSuccess',
              expect.anything(),
            );

            jest.advanceTimersByTime(10000);
          })
          .then(() => new Promise(resolve => requestAnimationFrame(resolve)))
          .then(() => {
            expect(axios.get).toHaveBeenCalled();
            expect(axios.get).toHaveBeenCalledTimes(2);
            expect(dispatch).toHaveBeenCalledWith(
              'receiveLatestPipelineSuccess',
              expect.anything(),
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet('/abc/def/commit/abc123def456ghi789jkl/pipelines').reply(500);
      });

      it('dispatches error', done => {
        const dispatch = jest.fn().mockName('dispatch');
        const rootGetters = {
          lastCommit: { id: 'abc123def456ghi789jkl' },
          currentProject: { path_with_namespace: 'abc/def' },
        };

        fetchLatestPipeline({ dispatch, rootGetters });

        jest.advanceTimersByTime(1500);

        new Promise(resolve => requestAnimationFrame(resolve))
          .then(() => {
            expect(dispatch).toHaveBeenCalledWith('receiveLatestPipelineError', expect.anything());
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('requestJobs', () => {
    it('commits request', done => {
      testAction(requestJobs, 1, mockedState, [{ type: types.REQUEST_JOBS, payload: 1 }], [], done);
    });
  });

  describe('receiveJobsError', () => {
    it('commits error', done => {
      testAction(
        receiveJobsError,
        { id: 1 },
        mockedState,
        [{ type: types.RECEIVE_JOBS_ERROR, payload: 1 }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'An error occurred whilst loading the pipelines jobs.',
              action: expect.anything(),
              actionText: 'Please try again',
              actionPayload: { id: 1 },
            },
          },
        ],
        done,
      );
    });
  });

  describe('receiveJobsSuccess', () => {
    it('commits data', done => {
      testAction(
        receiveJobsSuccess,
        { id: 1, data: jobs },
        mockedState,
        [{ type: types.RECEIVE_JOBS_SUCCESS, payload: { id: 1, data: jobs } }],
        [],
        done,
      );
    });
  });

  describe('fetchJobs', () => {
    const stage = { id: 1, dropdownPath: `${TEST_HOST}/jobs` };

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(stage.dropdownPath).replyOnce(200, jobs);
      });

      it('dispatches request', done => {
        testAction(
          fetchJobs,
          stage,
          mockedState,
          [],
          [
            { type: 'requestJobs', payload: stage.id },
            { type: 'receiveJobsSuccess', payload: { id: stage.id, data: jobs } },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(stage.dropdownPath).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchJobs,
          stage,
          mockedState,
          [],
          [
            { type: 'requestJobs', payload: stage.id },
            { type: 'receiveJobsError', payload: stage },
          ],
          done,
        );
      });
    });
  });

  describe('toggleStageCollapsed', () => {
    it('commits collapse', done => {
      testAction(
        toggleStageCollapsed,
        1,
        mockedState,
        [{ type: types.TOGGLE_STAGE_COLLAPSE, payload: 1 }],
        [],
        done,
      );
    });
  });

  describe('setDetailJob', () => {
    it('commits job', done => {
      testAction(
        setDetailJob,
        'job',
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: 'job' }],
        [{ type: 'rightPane/open', payload: rightSidebarViews.jobsDetail }],
        done,
      );
    });

    it('dispatches rightPane/open as pipeline when job is null', done => {
      testAction(
        setDetailJob,
        null,
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: null }],
        [{ type: 'rightPane/open', payload: rightSidebarViews.pipelines }],
        done,
      );
    });

    it('dispatches rightPane/open as job', done => {
      testAction(
        setDetailJob,
        'job',
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: 'job' }],
        [{ type: 'rightPane/open', payload: rightSidebarViews.jobsDetail }],
        done,
      );
    });
  });

  describe('requestJobTrace', () => {
    it('commits request', done => {
      testAction(requestJobTrace, null, mockedState, [{ type: types.REQUEST_JOB_TRACE }], [], done);
    });
  });

  describe('receiveJobTraceError', () => {
    it('commits error', done => {
      testAction(
        receiveJobTraceError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOB_TRACE_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'An error occurred whilst fetching the job trace.',
              action: expect.any(Function),
              actionText: 'Please try again',
              actionPayload: null,
            },
          },
        ],
        done,
      );
    });
  });

  describe('receiveJobTraceSuccess', () => {
    it('commits data', done => {
      testAction(
        receiveJobTraceSuccess,
        'data',
        mockedState,
        [{ type: types.RECEIVE_JOB_TRACE_SUCCESS, payload: 'data' }],
        [],
        done,
      );
    });
  });

  describe('fetchJobTrace', () => {
    beforeEach(() => {
      mockedState.detailJob = { path: `${TEST_HOST}/project/builds` };
    });

    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(axios, 'get');
        mock.onGet(`${TEST_HOST}/project/builds/trace`).replyOnce(200, { html: 'html' });
      });

      it('dispatches request', done => {
        testAction(
          fetchJobTrace,
          null,
          mockedState,
          [],
          [
            { type: 'requestJobTrace' },
            { type: 'receiveJobTraceSuccess', payload: { html: 'html' } },
          ],
          done,
        );
      });

      it('sends get request to correct URL', () => {
        fetchJobTrace({
          state: mockedState,

          dispatch() {},
        });
        expect(axios.get).toHaveBeenCalledWith(`${TEST_HOST}/project/builds/trace`, {
          params: { format: 'json' },
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/project/builds/trace`).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchJobTrace,
          null,
          mockedState,
          [],
          [{ type: 'requestJobTrace' }, { type: 'receiveJobTraceError' }],
          done,
        );
      });
    });
  });

  describe('resetLatestPipeline', () => {
    it('commits reset mutations', done => {
      testAction(
        resetLatestPipeline,
        null,
        mockedState,
        [
          { type: types.RECEIVE_LASTEST_PIPELINE_SUCCESS, payload: null },
          { type: types.SET_DETAIL_JOB, payload: null },
        ],
        [],
        done,
      );
    });
  });
});
