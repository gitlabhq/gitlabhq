import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import state from '~/ide/stores/modules/branches/state';
import * as types from '~/ide/stores/modules/branches/mutation_types';
import {
  requestBranches,
  receiveBranchesError,
  receiveBranchesSuccess,
  fetchBranches,
  resetBranches,
} from '~/ide/stores/modules/branches/actions';
import { branches, projectData } from '../../../mock_data';

describe('IDE branches actions', () => {
  const TEST_SEARCH = 'foosearch';
  let mockedContext;
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedContext = {
      dispatch() {},
      rootState: { currentProjectId: projectData.name_with_namespace },
      rootGetters: { currentProject: projectData },
      state: state(),
    };

    // testAction looks for rootGetters in state,
    // so they need to be concatenated here.
    mockedState = {
      ...mockedContext.state,
      ...mockedContext.rootGetters,
      ...mockedContext.rootState,
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestBranches', () => {
    it('should commit request', done => {
      testAction(
        requestBranches,
        null,
        mockedContext.state,
        [{ type: types.REQUEST_BRANCHES }],
        [],
        done,
      );
    });
  });

  describe('receiveBranchesError', () => {
    it('should commit error', done => {
      testAction(
        receiveBranchesError,
        { search: TEST_SEARCH },
        mockedContext.state,
        [{ type: types.RECEIVE_BRANCHES_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'Error loading branches.',
              action: expect.any(Function),
              actionText: 'Please try again',
              actionPayload: { search: TEST_SEARCH },
            },
          },
        ],
        done,
      );
    });
  });

  describe('receiveBranchesSuccess', () => {
    it('should commit received data', done => {
      testAction(
        receiveBranchesSuccess,
        branches,
        mockedContext.state,
        [{ type: types.RECEIVE_BRANCHES_SUCCESS, payload: branches }],
        [],
        done,
      );
    });
  });

  describe('fetchBranches', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/projects\/\d+\/repository\/branches(.*)$/).replyOnce(200, branches);
      });

      it('calls API with params', () => {
        const apiSpy = jest.spyOn(axios, 'get');

        fetchBranches(mockedContext, { search: TEST_SEARCH });

        expect(apiSpy).toHaveBeenCalledWith(expect.anything(), {
          params: expect.objectContaining({ search: TEST_SEARCH, sort: 'updated_desc' }),
        });
      });

      it('dispatches success with received data', done => {
        testAction(
          fetchBranches,
          { search: TEST_SEARCH },
          mockedState,
          [],
          [
            { type: 'requestBranches' },
            { type: 'resetBranches' },
            { type: 'receiveBranchesSuccess', payload: branches },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/projects\/\d+\/repository\/branches(.*)$/).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchBranches,
          { search: TEST_SEARCH },
          mockedState,
          [],
          [
            { type: 'requestBranches' },
            { type: 'resetBranches' },
            { type: 'receiveBranchesError', payload: { search: TEST_SEARCH } },
          ],
          done,
        );
      });
    });

    describe('resetBranches', () => {
      it('commits reset', done => {
        testAction(
          resetBranches,
          null,
          mockedContext.state,
          [{ type: types.RESET_BRANCHES }],
          [],
          done,
        );
      });
    });
  });
});
