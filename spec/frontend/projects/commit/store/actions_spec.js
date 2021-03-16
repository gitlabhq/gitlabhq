import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { PROJECT_BRANCHES_ERROR } from '~/projects/commit/constants';
import * as actions from '~/projects/commit/store/actions';
import * as types from '~/projects/commit/store/mutation_types';
import getInitialState from '~/projects/commit/store/state';
import mockData from '../mock_data';

jest.mock('~/flash.js');

describe('Commit form modal store actions', () => {
  let axiosMock;
  let state;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    state = getInitialState();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('clearModal', () => {
    it('commits CLEAR_MODAL mutation', () => {
      testAction(actions.clearModal, {}, {}, [
        {
          type: types.CLEAR_MODAL,
        },
      ]);
    });
  });

  describe('requestBranches', () => {
    it('commits REQUEST_BRANCHES mutation', () => {
      testAction(actions.requestBranches, {}, {}, [
        {
          type: types.REQUEST_BRANCHES,
        },
      ]);
    });
  });

  describe('fetchBranches', () => {
    it('dispatch correct actions on fetchBranches', (done) => {
      jest
        .spyOn(axios, 'get')
        .mockImplementation(() => Promise.resolve({ data: { Branches: mockData.mockBranches } }));

      testAction(
        actions.fetchBranches,
        {},
        state,
        [
          {
            type: types.RECEIVE_BRANCHES_SUCCESS,
            payload: mockData.mockBranches,
          },
        ],
        [{ type: 'requestBranches' }],
        () => {
          done();
        },
      );
    });

    it('should show flash error and set error in state on fetchBranches failure', (done) => {
      jest.spyOn(axios, 'get').mockRejectedValue();

      testAction(actions.fetchBranches, {}, state, [], [{ type: 'requestBranches' }], () => {
        expect(createFlash).toHaveBeenCalledWith({ message: PROJECT_BRANCHES_ERROR });
        done();
      });
    });
  });

  describe('setBranch', () => {
    it('commits SET_BRANCH mutation', () => {
      testAction(
        actions.setBranch,
        {},
        {},
        [
          {
            type: types.SET_BRANCH,
            payload: {},
          },
        ],
        [
          {
            type: 'setSelectedBranch',
            payload: {},
          },
        ],
      );
    });
  });

  describe('setSelectedBranch', () => {
    it('commits SET_SELECTED_BRANCH mutation', () => {
      testAction(actions.setSelectedBranch, {}, {}, [
        {
          type: types.SET_SELECTED_BRANCH,
          payload: {},
        },
      ]);
    });
  });

  describe('setBranchesEndpoint', () => {
    it('commits SET_BRANCHES_ENDPOINT mutation', () => {
      const endpoint = 'some/endpoint';

      testAction(actions.setBranchesEndpoint, endpoint, {}, [
        {
          type: types.SET_BRANCHES_ENDPOINT,
          payload: endpoint,
        },
      ]);
    });
  });

  describe('setSelectedProject', () => {
    const id = 1;

    it('commits SET_SELECTED_PROJECT mutation', () => {
      testAction(
        actions.setSelectedProject,
        id,
        {},
        [
          {
            type: types.SET_SELECTED_PROJECT,
            payload: id,
          },
        ],
        [
          {
            type: 'setBranchesEndpoint',
          },
          {
            type: 'fetchBranches',
          },
        ],
      );
    });
  });
});
