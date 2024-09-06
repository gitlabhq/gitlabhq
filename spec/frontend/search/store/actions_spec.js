import MockAdapter from 'axios-mock-adapter';
import { mapValues } from 'lodash';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { createAlert } from '~/alert';
import * as logger from '~/lib/logger';
import axios from '~/lib/utils/axios_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtils from '~/lib/utils/url_utility';
import * as actions from '~/search/store/actions';
import {
  GROUPS_LOCAL_STORAGE_KEY,
  PROJECTS_LOCAL_STORAGE_KEY,
  SIDEBAR_PARAMS,
  REGEX_PARAM,
  LS_REGEX_HANDLE,
} from '~/search/store/constants';
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
  PRELOAD_EXPECTED_MUTATIONS,
  PROMISE_ALL_EXPECTED_MUTATIONS,
  MOCK_NAVIGATION_DATA,
  MOCK_NAVIGATION,
  MOCK_NAVIGATION_ACTION_MUTATION,
  MOCK_ENDPOINT_RESPONSE,
  MOCK_RECEIVE_AGGREGATIONS_SUCCESS_MUTATION,
  MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION,
  MOCK_AGGREGATIONS,
  MOCK_LABEL_AGGREGATIONS,
} from '../mock_data';

jest.mock('~/alert');

jest.mock('~/lib/logger', () => ({
  logError: jest.fn(),
}));

describe('Global Search Store Actions', () => {
  let mock;
  let state;

  const alertCallback = (callCount) => {
    expect(createAlert).toHaveBeenCalledTimes(callCount);
    createAlert.mockClear();
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
    action                   | axiosMock                                                                  | type         | expectedMutations                                                                                       | alertCallCount
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: HTTP_STATUS_OK, res: MOCK_GROUPS }}             | ${'success'} | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_SUCCESS, payload: MOCK_GROUPS }]}       | ${0}
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }} | ${'error'}   | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_ERROR }]}                               | ${1}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: HTTP_STATUS_OK, res: MOCK_PROJECTS }}           | ${'success'} | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_SUCCESS, payload: MOCK_PROJECTS }]} | ${0}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }} | ${'error'}   | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_ERROR }]}                           | ${1}
  `(`axios calls`, ({ action, axiosMock, type, expectedMutations, alertCallCount }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction({ action, state, expectedMutations }).then(() =>
            alertCallback(alertCallCount),
          );
        });
      });
    });
  });

  describe.each`
    action                          | axiosMock                                                       | type         | expectedMutations                               | alertCallCount
    ${actions.loadFrequentGroups}   | ${{ method: 'onGet', code: HTTP_STATUS_OK }}                    | ${'success'} | ${[PROMISE_ALL_EXPECTED_MUTATIONS.resGroups]}   | ${0}
    ${actions.loadFrequentGroups}   | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR }} | ${'error'}   | ${[]}                                           | ${1}
    ${actions.loadFrequentProjects} | ${{ method: 'onGet', code: HTTP_STATUS_OK }}                    | ${'success'} | ${[PROMISE_ALL_EXPECTED_MUTATIONS.resProjects]} | ${0}
    ${actions.loadFrequentProjects} | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR }} | ${'error'}   | ${[]}                                           | ${1}
  `('Promise.all calls', ({ action, axiosMock, type, expectedMutations, alertCallCount }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          state.frequentItems = {
            [GROUPS_LOCAL_STORAGE_KEY]: FRESH_STORED_DATA,
            [PROJECTS_LOCAL_STORAGE_KEY]: FRESH_STORED_DATA,
          };

          mock[axiosMock.method]().reply(axiosMock.code, MOCK_FRESH_DATA_RES);
        });

        it(`should dispatch the correct mutations`, () => {
          return testAction({ action, state, expectedMutations }).then(() => {
            alertCallback(alertCallCount);
          });
        });
      });
    });
  });

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
      it('calls Api.groupProjects with expected parameters', () => {
        actions.fetchProjects({ commit: mockCommit, state }, MOCK_QUERY.search);
        expect(Api.groupProjects).toHaveBeenCalledWith(state.query.group_id, state.query.search, {
          order_by: 'similarity',
          include_subgroups: true,
          with_shared: false,
        });
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
        expect(Api.projects).toHaveBeenCalledWith(state.query.search, {
          order_by: 'similarity',
        });
      });
    });
  });

  describe.each`
    payload                                      | isDirty  | isDirtyMutation
    ${{ key: SIDEBAR_PARAMS[0], value: 'test' }} | ${false} | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: false }]}
    ${{ key: SIDEBAR_PARAMS[0], value: 'test' }} | ${true}  | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: true }]}
    ${{ key: SIDEBAR_PARAMS[1], value: 'test' }} | ${false} | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: false }]}
    ${{ key: SIDEBAR_PARAMS[1], value: 'test' }} | ${true}  | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: true }]}
    ${{ key: 'non-sidebar', value: 'test' }}     | ${false} | ${[]}
    ${{ key: 'non-sidebar', value: 'test' }}     | ${true}  | ${[]}
  `('setQuery', ({ payload, isDirty, isDirtyMutation }) => {
    describe(`when filter param is ${payload.key} and utils.isSidebarDirty returns ${isDirty}`, () => {
      const expectedMutations = [{ type: types.SET_QUERY, payload }].concat(isDirtyMutation);

      beforeEach(() => {
        storeUtils.isSidebarDirty = jest.fn().mockReturnValue(isDirty);
      });

      it(`should dispatch the correct mutations`, () => {
        return testAction({ action: actions.setQuery, payload, state, expectedMutations });
      });
    });
  });

  describe.each`
    payload
    ${{ key: REGEX_PARAM, value: true }}
    ${{ key: REGEX_PARAM, value: { random: 'test' } }}
  `('setQuery', ({ payload }) => {
    describe(`when query param is ${payload.key}`, () => {
      beforeEach(() => {
        storeUtils.setDataToLS = jest.fn();
        actions.setQuery({ state, commit: jest.fn() }, payload);
      });

      it(`setsItem in local storage`, () => {
        expect(storeUtils.setDataToLS).toHaveBeenCalledWith(LS_REGEX_HANDLE, expect.anything());
      });
    });
  });

  describe('applyQuery', () => {
    beforeEach(() => {
      setWindowLocation('https://test/');
      jest.spyOn(urlUtils, 'visitUrl').mockReturnValue({});
    });

    it('calls visitUrl and setParams with the state.query', async () => {
      await testAction(actions.applyQuery, null, state, [], []);
      expect(urlUtils.visitUrl).toHaveBeenCalledWith(
        'https://test/?scope=issues&state=all&group_id=1&language%5B%5D=C&language%5B%5D=JavaScript&label_name%5B%5D=Aftersync&label_name%5B%5D=Brist&search=*',
      );
    });
  });

  describe('resetQuery', () => {
    beforeEach(() => {
      setWindowLocation('https://test/');
      jest.spyOn(urlUtils, 'visitUrl').mockReturnValue({});
      jest.spyOn(urlUtils, 'setUrlParams').mockReturnValue({});
    });

    it('calls visitUrl and setParams with empty values', async () => {
      await testAction(actions.resetQuery, null, state, [], []);
      const resetParams = SIDEBAR_PARAMS.reduce((acc, param) => {
        acc[param] = null;
        return acc;
      }, {});

      expect(urlUtils.setUrlParams).toHaveBeenCalledWith(
        {
          ...state.query,
          page: null,
          ...resetParams,
        },
        undefined,
        true,
      );
      expect(urlUtils.visitUrl).toHaveBeenCalled();
    });
  });

  describe('preloadStoredFrequentItems', () => {
    beforeEach(() => {
      storeUtils.loadDataFromLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
    });

    it('calls preloadStoredFrequentItems for both groups and projects and commits LOAD_FREQUENT_ITEMS', async () => {
      await testAction({
        action: actions.preloadStoredFrequentItems,
        state,
        expectedMutations: PRELOAD_EXPECTED_MUTATIONS,
      });

      expect(storeUtils.loadDataFromLS).toHaveBeenCalledTimes(2);
      expect(storeUtils.loadDataFromLS).toHaveBeenCalledWith(GROUPS_LOCAL_STORAGE_KEY);
      expect(storeUtils.loadDataFromLS).toHaveBeenCalledWith(PROJECTS_LOCAL_STORAGE_KEY);
    });
  });

  describe('setFrequentGroup', () => {
    beforeEach(() => {
      storeUtils.setFrequentItemToLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
    });

    it(`calls setFrequentItemToLS with ${GROUPS_LOCAL_STORAGE_KEY} and item data then commits LOAD_FREQUENT_ITEMS`, async () => {
      await testAction({
        action: actions.setFrequentGroup,
        expectedMutations: [
          {
            type: types.LOAD_FREQUENT_ITEMS,
            payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
          },
        ],
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
      storeUtils.setFrequentItemToLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
    });

    it(`calls setFrequentItemToLS with ${PROJECTS_LOCAL_STORAGE_KEY} and item data`, async () => {
      await testAction({
        action: actions.setFrequentProject,
        expectedMutations: [
          {
            type: types.LOAD_FREQUENT_ITEMS,
            payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
          },
        ],
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

  describe.each`
    action                       | axiosMock                                                       | type         | scope         | expectedMutations                    | errorLogs
    ${actions.fetchSidebarCount} | ${{ method: 'onGet', code: HTTP_STATUS_OK }}                    | ${'success'} | ${'issues'}   | ${[MOCK_NAVIGATION_ACTION_MUTATION]} | ${0}
    ${actions.fetchSidebarCount} | ${{ method: null, code: 0 }}                                    | ${'error'}   | ${'projects'} | ${[]}                                | ${1}
    ${actions.fetchSidebarCount} | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR }} | ${'error'}   | ${'issues'}   | ${[]}                                | ${1}
  `('fetchSidebarCount', ({ action, axiosMock, type, expectedMutations, scope, errorLogs }) => {
    describe(`on ${type}`, () => {
      beforeEach(() => {
        state.navigation = MOCK_NAVIGATION_DATA;
        state.urlQuery = {
          scope,
        };
        state.query = {
          search: 'et',
        };

        if (axiosMock.method) {
          mock[axiosMock.method]().reply(axiosMock.code, MOCK_ENDPOINT_RESPONSE);
        }
      });

      it(`should ${expectedMutations.length === 0 ? 'NOT' : ''} dispatch ${
        expectedMutations.length === 0 ? '' : 'the correct'
      } mutations for ${scope}`, () => {
        return testAction({ action, state, expectedMutations }).then(() => {
          expect(logger.logError).toHaveBeenCalledTimes(errorLogs);
        });
      });
    });
  });

  describe('fetchSidebarCount with no count_link', () => {
    beforeEach(() => {
      state.navigation = mapValues(MOCK_NAVIGATION_DATA, (navItem) => ({
        ...navItem,
        count_link: null,
      }));
    });

    it('should not request anything', async () => {
      await testAction({ action: actions.fetchSidebarCount, state, expectedMutations: [] });

      expect(mock.history.get.length).toBe(0);
    });
  });

  describe('fetchSidebarCount uses wild card seach', () => {
    beforeEach(() => {
      state.navigation = MOCK_NAVIGATION;
      state.urlQuery.search = '';
    });

    it('should use wild card', async () => {
      await testAction({ action: actions.fetchSidebarCount, state, expectedMutations: [] });
      expect(mock.history.get[0].url).toBe('http://test.host/search/count?scope=projects&search=*');
      expect(mock.history.get[3].url).toBe(
        'http://test.host/search/count?scope=merge_requests&search=*',
      );
    });
  });

  describe.each`
    action                         | axiosMock                                                       | type         | expectedMutations                             | errorLogs
    ${actions.fetchAllAggregation} | ${{ method: 'onGet', code: HTTP_STATUS_OK }}                    | ${'success'} | ${MOCK_RECEIVE_AGGREGATIONS_SUCCESS_MUTATION} | ${0}
    ${actions.fetchAllAggregation} | ${{ method: 'onPut', code: 0 }}                                 | ${'error'}   | ${MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION}   | ${1}
    ${actions.fetchAllAggregation} | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR }} | ${'error'}   | ${MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION}   | ${1}
  `('fetchAllAggregation', ({ action, axiosMock, type, expectedMutations, errorLogs }) => {
    describe(`on ${type}`, () => {
      beforeEach(() => {
        if (axiosMock.method) {
          mock[axiosMock.method]().reply(
            axiosMock.code,
            axiosMock.code === HTTP_STATUS_OK ? MOCK_AGGREGATIONS : [],
          );
        }
      });

      it(`should ${type === 'error' ? 'NOT ' : ''}dispatch ${
        type === 'error' ? '' : 'the correct '
      }mutations`, () => {
        return testAction({ action, state, expectedMutations }).then(() => {
          expect(logger.logError).toHaveBeenCalledTimes(errorLogs);
        });
      });
    });
  });

  describe('closeLabel', () => {
    beforeEach(() => {
      state = createState({
        query: MOCK_QUERY,
        aggregations: MOCK_LABEL_AGGREGATIONS,
      });
    });

    it('removes correct labels from query and sets sidebar dirty', () => {
      const expectedResult = [
        {
          payload: {
            key: 'label_name',
            value: ['Aftersync', 'Brist'],
          },
          type: 'SET_QUERY',
        },
        {
          payload: true,
          type: 'SET_SIDEBAR_DIRTY',
        },
      ];
      return testAction(actions.closeLabel, { key: '60' }, state, expectedResult, []);
    });
  });

  describe('setLabelFilterSearch', () => {
    beforeEach(() => {
      state = createState({
        query: MOCK_QUERY,
        aggregations: MOCK_LABEL_AGGREGATIONS,
      });
    });

    it('sets search string', () => {
      const expectedResult = [
        {
          payload: 'test',
          type: 'SET_LABEL_SEARCH_STRING',
        },
      ];
      return testAction(actions.setLabelFilterSearch, { value: 'test' }, state, expectedResult, []);
    });
  });
});
