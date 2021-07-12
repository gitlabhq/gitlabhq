import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import * as actions from '~/search/store/actions';
import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import * as types from '~/search/store/mutation_types';
import createState from '~/search/store/state';
import * as storeUtils from '~/search/store/utils';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECT,
  MOCK_PROJECTS,
  MOCK_GROUP,
  FRESH_STORED_DATA,
  MOCK_FRESH_DATA_RES,
  PROMISE_ALL_EXPECTED_MUTATIONS,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  setUrlParams: jest.fn(),
  joinPaths: jest.fn().mockReturnValue(''),
  visitUrl: jest.fn(),
}));

describe('Global Search Store Actions', () => {
  let mock;
  let state;

  const flashCallback = (callCount) => {
    expect(createFlash).toHaveBeenCalledTimes(callCount);
    createFlash.mockClear();
  };

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe.each`
    action                   | axiosMock                                             | type         | expectedMutations                                                                                       | flashCallCount
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: 200, res: MOCK_GROUPS }}   | ${'success'} | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_SUCCESS, payload: MOCK_GROUPS }]}       | ${0}
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: 500, res: null }}          | ${'error'}   | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_ERROR }]}                               | ${1}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: 200, res: MOCK_PROJECTS }} | ${'success'} | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_SUCCESS, payload: MOCK_PROJECTS }]} | ${0}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: 500, res: null }}          | ${'error'}   | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_ERROR }]}                           | ${2}
  `(`axios calls`, ({ action, axiosMock, type, expectedMutations, flashCallCount }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction({ action, state, expectedMutations }).then(() =>
            flashCallback(flashCallCount),
          );
        });
      });
    });
  });

  describe.each`
    action                          | axiosMock                         | type         | expectedMutations                                                                            | flashCallCount | lsKey
    ${actions.loadFrequentGroups}   | ${{ method: 'onGet', code: 200 }} | ${'success'} | ${[PROMISE_ALL_EXPECTED_MUTATIONS.initGroups, PROMISE_ALL_EXPECTED_MUTATIONS.resGroups]}     | ${0}           | ${GROUPS_LOCAL_STORAGE_KEY}
    ${actions.loadFrequentGroups}   | ${{ method: 'onGet', code: 500 }} | ${'error'}   | ${[PROMISE_ALL_EXPECTED_MUTATIONS.initGroups]}                                               | ${1}           | ${GROUPS_LOCAL_STORAGE_KEY}
    ${actions.loadFrequentProjects} | ${{ method: 'onGet', code: 200 }} | ${'success'} | ${[PROMISE_ALL_EXPECTED_MUTATIONS.initProjects, PROMISE_ALL_EXPECTED_MUTATIONS.resProjects]} | ${0}           | ${PROJECTS_LOCAL_STORAGE_KEY}
    ${actions.loadFrequentProjects} | ${{ method: 'onGet', code: 500 }} | ${'error'}   | ${[PROMISE_ALL_EXPECTED_MUTATIONS.initProjects]}                                             | ${1}           | ${PROJECTS_LOCAL_STORAGE_KEY}
  `(
    'Promise.all calls',
    ({ action, axiosMock, type, expectedMutations, flashCallCount, lsKey }) => {
      describe(action.name, () => {
        describe(`on ${type}`, () => {
          beforeEach(() => {
            storeUtils.loadDataFromLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
            mock[axiosMock.method]().reply(axiosMock.code, MOCK_FRESH_DATA_RES);
          });

          it(`should dispatch the correct mutations`, () => {
            return testAction({ action, state, expectedMutations }).then(() => {
              expect(storeUtils.loadDataFromLS).toHaveBeenCalledWith(lsKey);
              flashCallback(flashCallCount);
            });
          });
        });
      });
    },
  );

  describe('getGroupsData', () => {
    const mockCommit = () => {};
    beforeEach(() => {
      jest.spyOn(Api, 'groups').mockResolvedValue(MOCK_GROUPS);
    });

    it('calls Api.groups with order_by set to similarity', () => {
      actions.fetchGroups({ commit: mockCommit }, 'test');

      expect(Api.groups).toHaveBeenCalledWith('test', { order_by: 'similarity' });
    });
  });

  describe('getProjectsData', () => {
    const mockCommit = () => {};
    beforeEach(() => {
      jest.spyOn(Api, 'groupProjects').mockResolvedValue(MOCK_PROJECTS);
      jest.spyOn(Api, 'projects').mockResolvedValue(MOCK_PROJECT);
    });

    describe('when groupId is set', () => {
      it('calls Api.groupProjects', () => {
        actions.fetchProjects({ commit: mockCommit, state });

        expect(Api.groupProjects).toHaveBeenCalledWith(
          state.query.group_id,
          state.query.search,
          {
            order_by: 'similarity',
          },
          expect.any(Function),
        );
        expect(Api.projects).not.toHaveBeenCalled();
      });
    });

    describe('when groupId is not set', () => {
      beforeEach(() => {
        state = createState({ query: { group_id: null } });
      });

      it('calls Api.projects', () => {
        actions.fetchProjects({ commit: mockCommit, state });

        expect(Api.groupProjects).not.toHaveBeenCalled();
        expect(Api.projects).toHaveBeenCalled();
      });
    });
  });

  describe('setQuery', () => {
    const payload = { key: 'key1', value: 'value1' };

    it('calls the SET_QUERY mutation', () => {
      return testAction({
        action: actions.setQuery,
        payload,
        state,
        expectedMutations: [{ type: types.SET_QUERY, payload }],
      });
    });
  });

  describe('applyQuery', () => {
    it('calls visitUrl and setParams with the state.query', () => {
      return testAction(actions.applyQuery, null, state, [], [], () => {
        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({ ...state.query, page: null });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('resetQuery', () => {
    it('calls visitUrl and setParams with empty values', () => {
      return testAction(actions.resetQuery, null, state, [], [], () => {
        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({
          ...state.query,
          page: null,
          state: null,
          confidential: null,
        });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('setFrequentGroup', () => {
    beforeEach(() => {
      storeUtils.setFrequentItemToLS = jest.fn();
    });

    it(`calls setFrequentItemToLS with ${GROUPS_LOCAL_STORAGE_KEY} and item data`, async () => {
      await testAction({
        action: actions.setFrequentGroup,
        payload: MOCK_GROUP,
        state,
      });

      expect(storeUtils.setFrequentItemToLS).toHaveBeenCalledWith(
        GROUPS_LOCAL_STORAGE_KEY,
        state.frequentItems,
        MOCK_GROUP,
      );
    });
  });

  describe('setFrequentProject', () => {
    beforeEach(() => {
      storeUtils.setFrequentItemToLS = jest.fn();
    });

    it(`calls setFrequentItemToLS with ${PROJECTS_LOCAL_STORAGE_KEY} and item data`, async () => {
      await testAction({
        action: actions.setFrequentProject,
        payload: MOCK_PROJECT,
        state,
      });

      expect(storeUtils.setFrequentItemToLS).toHaveBeenCalledWith(
        PROJECTS_LOCAL_STORAGE_KEY,
        state.frequentItems,
        MOCK_PROJECT,
      );
    });
  });
});
