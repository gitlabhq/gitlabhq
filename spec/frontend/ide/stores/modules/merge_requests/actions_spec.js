import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import {
  requestMergeRequests,
  receiveMergeRequestsError,
  receiveMergeRequestsSuccess,
  fetchMergeRequests,
  resetMergeRequests,
} from '~/ide/stores/modules/merge_requests/actions';
import * as types from '~/ide/stores/modules/merge_requests/mutation_types';
import state from '~/ide/stores/modules/merge_requests/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mergeRequests } from '../../../mock_data';

describe('IDE merge requests actions', () => {
  let mockedState;
  let mockedRootState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mockedRootState = { currentProjectId: 7 };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestMergeRequests', () => {
    it('should commit request', () => {
      return testAction(
        requestMergeRequests,
        null,
        mockedState,
        [{ type: types.REQUEST_MERGE_REQUESTS }],
        [],
      );
    });
  });

  describe('receiveMergeRequestsError', () => {
    it('should commit error', () => {
      return testAction(
        receiveMergeRequestsError,
        { type: 'created', search: '' },
        mockedState,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'Error loading merge requests.',
              action: expect.any(Function),
              actionText: 'Please try again',
              actionPayload: { type: 'created', search: '' },
            },
          },
        ],
      );
    });
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('should commit received data', () => {
      return testAction(
        receiveMergeRequestsSuccess,
        mergeRequests,
        mockedState,
        [{ type: types.RECEIVE_MERGE_REQUESTS_SUCCESS, payload: mergeRequests }],
        [],
      );
    });
  });

  describe('fetchMergeRequests', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/merge_requests\/?/).replyOnce(HTTP_STATUS_OK, mergeRequests);
      });

      it('calls API with params', () => {
        const apiSpy = jest.spyOn(axios, 'get');
        fetchMergeRequests(
          {
            dispatch() {},

            state: mockedState,
            rootState: mockedRootState,
          },
          { type: 'created' },
        );
        expect(apiSpy).toHaveBeenCalledWith(expect.anything(), {
          params: { scope: 'created-by-me', state: 'opened', search: '' },
        });
      });

      it('calls API with search', () => {
        const apiSpy = jest.spyOn(axios, 'get');
        fetchMergeRequests(
          {
            dispatch() {},

            state: mockedState,
            rootState: mockedRootState,
          },
          { type: 'created', search: 'testing search' },
        );
        expect(apiSpy).toHaveBeenCalledWith(expect.anything(), {
          params: { scope: 'created-by-me', state: 'opened', search: 'testing search' },
        });
      });

      it('dispatches success with received data', () => {
        return testAction(
          fetchMergeRequests,
          { type: 'created' },
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsSuccess', payload: mergeRequests },
          ],
        );
      });
    });

    describe('success without type', () => {
      beforeEach(() => {
        mock
          .onGet(/\/api\/v4\/projects\/.+\/merge_requests\/?$/)
          .replyOnce(HTTP_STATUS_OK, mergeRequests);
      });

      it('calls API with project', () => {
        const apiSpy = jest.spyOn(axios, 'get');
        fetchMergeRequests(
          {
            dispatch() {},

            state: mockedState,
            rootState: mockedRootState,
          },
          { type: null, search: 'testing search' },
        );
        expect(apiSpy).toHaveBeenCalledWith(
          expect.stringMatching(`projects/${mockedRootState.currentProjectId}/merge_requests`),
          { params: { state: 'opened', search: 'testing search' } },
        );
      });

      it('dispatches success with received data', () => {
        return testAction(
          fetchMergeRequests,
          { type: null },
          { ...mockedState, ...mockedRootState },
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsSuccess', payload: mergeRequests },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/merge_requests(.*)$/).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', () => {
        return testAction(
          fetchMergeRequests,
          { type: 'created', search: '' },
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsError', payload: { type: 'created', search: '' } },
          ],
        );
      });
    });
  });

  describe('resetMergeRequests', () => {
    it('commits reset', () => {
      return testAction(
        resetMergeRequests,
        null,
        mockedState,
        [{ type: types.RESET_MERGE_REQUESTS }],
        [],
      );
    });
  });
});
