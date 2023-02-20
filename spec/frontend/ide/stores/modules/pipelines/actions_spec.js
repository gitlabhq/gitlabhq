import MockAdapter from 'axios-mock-adapter';
import Visibility from 'visibilityjs';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { rightSidebarViews } from '~/ide/constants';
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
  requestJobLogs,
  receiveJobLogsError,
  receiveJobLogsSuccess,
  fetchJobLogs,
  resetLatestPipeline,
} from '~/ide/stores/modules/pipelines/actions';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import state from '~/ide/stores/modules/pipelines/state';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
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
    it('commits request', () => {
      return testAction(
        requestLatestPipeline,
        null,
        mockedState,
        [{ type: types.REQUEST_LATEST_PIPELINE }],
        [],
      );
    });
  });

  describe('receiveLatestPipelineError', () => {
    it('commits error', () => {
      return testAction(
        receiveLatestPipelineError,
        { status: HTTP_STATUS_NOT_FOUND },
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_ERROR }],
        [{ type: 'stopPipelinePolling' }],
      );
    });

    it('dispatches setErrorMessage is not 404', () => {
      return testAction(
        receiveLatestPipelineError,
        { status: HTTP_STATUS_INTERNAL_SERVER_ERROR },
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'An error occurred while fetching the latest pipeline.',
              action: expect.any(Function),
              actionText: 'Please try again',
              actionPayload: null,
            },
          },
          { type: 'stopPipelinePolling' },
        ],
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
          .reply(HTTP_STATUS_OK, { data: { foo: 'bar' } }, { 'poll-interval': '10000' });
      });

      it('dispatches request', async () => {
        jest.spyOn(axios, 'get');
        jest.spyOn(Visibility, 'hidden').mockReturnValue(false);

        const dispatch = jest.fn().mockName('dispatch');
        const rootGetters = {
          lastCommit: { id: 'abc123def456ghi789jkl' },
          currentProject: { path_with_namespace: 'abc/def' },
        };

        await fetchLatestPipeline({ dispatch, rootGetters });

        expect(dispatch).toHaveBeenCalledWith('requestLatestPipeline');

        await waitForPromises();

        expect(axios.get).toHaveBeenCalled();
        expect(axios.get).toHaveBeenCalledTimes(1);
        expect(dispatch).toHaveBeenCalledWith('receiveLatestPipelineSuccess', expect.anything());

        jest.advanceTimersByTime(10000);

        expect(axios.get).toHaveBeenCalled();
        expect(axios.get).toHaveBeenCalledTimes(2);
        expect(dispatch).toHaveBeenCalledWith('receiveLatestPipelineSuccess', expect.anything());
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock
          .onGet('/abc/def/commit/abc123def456ghi789jkl/pipelines')
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', async () => {
        const dispatch = jest.fn().mockName('dispatch');
        const rootGetters = {
          lastCommit: { id: 'abc123def456ghi789jkl' },
          currentProject: { path_with_namespace: 'abc/def' },
        };

        await fetchLatestPipeline({ dispatch, rootGetters });

        await waitForPromises();

        expect(dispatch).toHaveBeenCalledWith('receiveLatestPipelineError', expect.anything());
      });
    });

    it('sets latest pipeline to `null` and stops polling on empty project', () => {
      mockedState = {
        ...mockedState,
        rootGetters: {
          lastCommit: null,
        },
      };

      return testAction(
        fetchLatestPipeline,
        {},
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_SUCCESS, payload: null }],
        [{ type: 'stopPipelinePolling' }],
      );
    });
  });

  describe('requestJobs', () => {
    it('commits request', () => {
      return testAction(
        requestJobs,
        1,
        mockedState,
        [{ type: types.REQUEST_JOBS, payload: 1 }],
        [],
      );
    });
  });

  describe('receiveJobsError', () => {
    it('commits error', () => {
      return testAction(
        receiveJobsError,
        { id: 1 },
        mockedState,
        [{ type: types.RECEIVE_JOBS_ERROR, payload: 1 }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'An error occurred while loading the pipelines jobs.',
              action: expect.anything(),
              actionText: 'Please try again',
              actionPayload: { id: 1 },
            },
          },
        ],
      );
    });
  });

  describe('receiveJobsSuccess', () => {
    it('commits data', () => {
      return testAction(
        receiveJobsSuccess,
        { id: 1, data: jobs },
        mockedState,
        [{ type: types.RECEIVE_JOBS_SUCCESS, payload: { id: 1, data: jobs } }],
        [],
      );
    });
  });

  describe('fetchJobs', () => {
    const stage = { id: 1, dropdownPath: `${TEST_HOST}/jobs` };

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(stage.dropdownPath).replyOnce(HTTP_STATUS_OK, jobs);
      });

      it('dispatches request', () => {
        return testAction(
          fetchJobs,
          stage,
          mockedState,
          [],
          [
            { type: 'requestJobs', payload: stage.id },
            { type: 'receiveJobsSuccess', payload: { id: stage.id, data: jobs } },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(stage.dropdownPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', () => {
        return testAction(
          fetchJobs,
          stage,
          mockedState,
          [],
          [
            { type: 'requestJobs', payload: stage.id },
            { type: 'receiveJobsError', payload: stage },
          ],
        );
      });
    });
  });

  describe('toggleStageCollapsed', () => {
    it('commits collapse', () => {
      return testAction(
        toggleStageCollapsed,
        1,
        mockedState,
        [{ type: types.TOGGLE_STAGE_COLLAPSE, payload: 1 }],
        [],
      );
    });
  });

  describe('setDetailJob', () => {
    it('commits job', () => {
      return testAction(
        setDetailJob,
        'job',
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: 'job' }],
        [{ type: 'rightPane/open', payload: rightSidebarViews.jobsDetail }],
      );
    });

    it('dispatches rightPane/open as pipeline when job is null', () => {
      return testAction(
        setDetailJob,
        null,
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: null }],
        [{ type: 'rightPane/open', payload: rightSidebarViews.pipelines }],
      );
    });

    it('dispatches rightPane/open as job', () => {
      return testAction(
        setDetailJob,
        'job',
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: 'job' }],
        [{ type: 'rightPane/open', payload: rightSidebarViews.jobsDetail }],
      );
    });
  });

  describe('requestJobLogs', () => {
    it('commits request', () => {
      return testAction(requestJobLogs, null, mockedState, [{ type: types.REQUEST_JOB_LOGS }], []);
    });
  });

  describe('receiveJobLogsError', () => {
    it('commits error', () => {
      return testAction(
        receiveJobLogsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOB_LOGS_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'An error occurred while fetching the job logs.',
              action: expect.any(Function),
              actionText: 'Please try again',
              actionPayload: null,
            },
          },
        ],
      );
    });
  });

  describe('receiveJobLogsSuccess', () => {
    it('commits data', () => {
      return testAction(
        receiveJobLogsSuccess,
        'data',
        mockedState,
        [{ type: types.RECEIVE_JOB_LOGS_SUCCESS, payload: 'data' }],
        [],
      );
    });
  });

  describe('fetchJobLogs', () => {
    beforeEach(() => {
      mockedState.detailJob = { path: `${TEST_HOST}/project/builds` };
    });

    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(axios, 'get');
        mock.onGet(`${TEST_HOST}/project/builds/trace`).replyOnce(HTTP_STATUS_OK, { html: 'html' });
      });

      it('dispatches request', () => {
        return testAction(
          fetchJobLogs,
          null,
          mockedState,
          [],
          [
            { type: 'requestJobLogs' },
            { type: 'receiveJobLogsSuccess', payload: { html: 'html' } },
          ],
        );
      });

      it('sends get request to correct URL', () => {
        fetchJobLogs({
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
        mock
          .onGet(`${TEST_HOST}/project/builds/trace`)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', () => {
        return testAction(
          fetchJobLogs,
          null,
          mockedState,
          [],
          [{ type: 'requestJobLogs' }, { type: 'receiveJobLogsError' }],
        );
      });
    });
  });

  describe('resetLatestPipeline', () => {
    it('commits reset mutations', () => {
      return testAction(
        resetLatestPipeline,
        null,
        mockedState,
        [
          { type: types.RECEIVE_LASTEST_PIPELINE_SUCCESS, payload: null },
          { type: types.SET_DETAIL_JOB, payload: null },
        ],
        [],
      );
    });
  });
});
