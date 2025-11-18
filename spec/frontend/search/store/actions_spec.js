import MockAdapter from 'axios-mock-adapter';
import { mapValues } from 'lodash';
// rspec spec/frontend/fixtures/search_navigation.rb to generate this file
import noActiveItems from 'test_fixtures/search_navigation/no_active_items.json';
import testAction from 'helpers/vuex_action_helper';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import Api from '~/api';
import { createAlert } from '~/alert';
import * as logger from '~/lib/logger';
import axios from '~/lib/utils/axios_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtils from '~/lib/utils/url_utility';

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
import * as actions from '~/search/store/actions';
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

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtility = jest.requireActual('~/lib/utils/url_utility');

  return {
    __esModule: true,
    ...urlUtility,
    setUrlParams: jest.fn(() => 'mocked-new-url'),
    updateHistory: jest.fn(),
  };
});

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

  describe('setQuery', () => {
    describe('when search type is zoekt and scope is blob', () => {
      const payload = { key: 'some-key', value: 'some-value' };
      let originalGon;
      let commit;
      let fetchSidebarCountSpy;

      beforeEach(() => {
        originalGon = window.gon;
        commit = jest.fn();

        fetchSidebarCountSpy = jest
          .spyOn(actions, 'fetchSidebarCount')
          .mockImplementation(() => Promise.resolve());

        window.gon = { features: {} };
        storeUtils.isSidebarDirty = jest.fn().mockReturnValue(false);

        state = createState({
          query: { ...MOCK_QUERY, search: 'test-search' },
          navigation: { ...MOCK_NAVIGATION },
          searchType: 'zoekt',
        });
      });

      afterEach(() => {
        window.gon = originalGon;
        fetchSidebarCountSpy.mockRestore();
      });

      it('should update URL, document title, and history', () => {
        const getters = { currentScope: 'blobs' };

        return testAction(actions.setQuery, payload, { ...state, ...getters }, [
          { type: types.SET_QUERY, payload: { key: 'some-key', value: 'some-value' } },
        ]);
      });

      it('does not update URL or fetch sidebar counts when conditions are not met', async () => {
        let getters = { currentScope: 'blobs' };
        state.searchType = 'not-zoekt';

        await actions.setQuery({ state, commit, getters }, payload);

        expect(setUrlParams).not.toHaveBeenCalled();
        expect(updateHistory).not.toHaveBeenCalled();
        expect(fetchSidebarCountSpy).not.toHaveBeenCalled();

        setUrlParams.mockClear();
        updateHistory.mockClear();
        fetchSidebarCountSpy.mockClear();

        state.searchType = 'zoekt';
        getters = { currentScope: 'not-blobs' };

        await actions.setQuery({ state, commit, getters }, payload);

        expect(setUrlParams).not.toHaveBeenCalled();
        expect(updateHistory).not.toHaveBeenCalled();
        expect(fetchSidebarCountSpy).not.toHaveBeenCalled();
      });
    });

    describe.each`
      payload
      ${{ key: REGEX_PARAM, value: true }}
      ${{ key: REGEX_PARAM, value: { random: 'test' } }}
    `('setQuery with REGEX_PARAM', ({ payload }) => {
      describe(`when query param is ${payload.key}`, () => {
        beforeEach(() => {
          storeUtils.setDataToLS = jest.fn();
          window.gon = { features: {} };
          const getters = { currentScope: 'not-blobs' };
          actions.setQuery({ state, commit: jest.fn(), getters }, payload);
        });

        it(`setsItem in local storage`, () => {
          expect(storeUtils.setDataToLS).toHaveBeenCalledWith(LS_REGEX_HANDLE, expect.anything());
        });
      });
    });

    describe('zoekt search type with blob scope - page handling scenarios', () => {
      let originalGon;
      let commit;
      let fetchSidebarCountSpy;
      let modifySearchQuerySpy;

      beforeEach(() => {
        originalGon = window.gon;
        commit = jest.fn();

        fetchSidebarCountSpy = jest
          .spyOn(actions, 'fetchSidebarCount')
          .mockImplementation(() => Promise.resolve());

        modifySearchQuerySpy = jest
          .spyOn(storeUtils, 'modifySearchQuery')
          .mockReturnValue('mocked-clean-url');

        window.gon = { features: {} };
        storeUtils.isSidebarDirty = jest.fn().mockReturnValue(false);
        storeUtils.buildDocumentTitle = jest.fn().mockReturnValue('Built Document Title');

        state = createState({
          query: { ...MOCK_QUERY, search: 'test-search' },
          navigation: { ...MOCK_NAVIGATION },
          searchType: 'zoekt',
        });
      });

      afterEach(() => {
        window.gon = originalGon;
        fetchSidebarCountSpy.mockRestore();
        modifySearchQuerySpy.mockRestore();
      });

      describe('when only "page" attribute changes', () => {
        it('should only update history without fetching sidebar counts', async () => {
          const getters = { currentScope: 'blobs' };
          const payload = { key: 'page', value: 2 };

          await actions.setQuery({ state, commit, getters }, payload);

          expect(setUrlParams).toHaveBeenCalledWith(
            { ...state.query },
            { url: window.location.href, clearParams: true, railsArraySyntax: true },
          );

          expect(updateHistory).toHaveBeenCalledWith({
            state: state.query,
            title: state.query.search,
            url: 'mocked-new-url',
            replace: true,
          });

          expect(fetchSidebarCountSpy).not.toHaveBeenCalled();
          expect(commit).toHaveBeenCalledWith(types.SET_QUERY, payload);
        });
      });

      describe('when "search" attribute changes and page attribute is not present', () => {
        beforeEach(() => {
          const res = { count: 666 };
          mock.onGet().replyOnce(HTTP_STATUS_OK, res);
        });

        it('should update URL, title, history and fetch sidebar counts', async () => {
          const getters = { currentScope: 'blobs' };
          const payload = { key: 'search', value: 'new-search' };

          state.query = { ...state.query };
          delete state.query.page;
          state.urlQuery = { ...state.urlQuery };
          delete state.urlQuery.page;

          await testAction(
            actions.setQuery,
            payload,
            { ...state, ...getters },
            [{ type: types.SET_QUERY, payload: { key: 'search', value: 'new-search' } }],
            [{ type: 'fetchSidebarCount' }],
          );
        });
      });

      describe('when "search" attribute changes but page is present and not equal to 1', () => {
        it('should reset page to 1, update URL with clean URL, and fetch sidebar counts', () => {
          const getters = { currentScope: 'blobs' };
          const payload = { key: 'search', value: 'new-search' };

          state.query = { ...state.query, page: 3 };
          state.urlQuery = { ...state.urlQuery, page: 3 };

          return testAction(
            actions.setQuery,
            payload,
            { ...state, ...getters },
            [
              { type: types.SET_QUERY, payload: { key: 'search', value: 'new-search' } },
              { type: types.SET_QUERY, payload: { key: 'page', value: 1 } },
            ],
            [{ type: 'fetchSidebarCount' }],
          );
        });
      });

      describe('when "search" attribute changes but page is present and equal to 1', () => {
        it('should not modify URL for page, update history with original URL', async () => {
          const getters = { currentScope: 'blobs' };
          const payload = { key: 'search', value: 'new-search' };

          state.query = { ...state.query, page: 1 };
          state.urlQuery = { ...state.urlQuery, page: 1 };

          await testAction(
            actions.setQuery,
            payload,
            { ...state, ...getters },
            [{ type: types.SET_QUERY, payload: { key: 'search', value: 'new-search' } }],
            [{ type: 'fetchSidebarCount' }],
          );

          expect(updateHistory).toHaveBeenCalled();
        });
      });

      describe('when urlQuery has no page but state.query has page', () => {
        it('should use original URL without modification', () => {
          const getters = { currentScope: 'blobs' };
          const payload = { key: 'search', value: 'new-search' };

          state.query = { ...state.query, page: 2 };
          state.urlQuery = { ...state.urlQuery };
          delete state.urlQuery.page;

          return testAction(
            actions.setQuery,
            payload,
            { ...state, ...getters },
            [
              { type: types.SET_QUERY, payload: { key: 'search', value: 'new-search' } },
              { type: types.SET_QUERY, payload: { key: 'page', value: 1 } },
            ],
            [{ type: 'fetchSidebarCount' }],
          );
        });
      });
    });
  });

  describe('applyQuery', () => {
    beforeEach(() => {
      setWindowLocation('https://test/');
      jest.spyOn(urlUtils, 'visitUrl').mockImplementation(() => {});
      jest
        .spyOn(urlUtils, 'setUrlParams')
        .mockReturnValue(
          'https://test/?scope=issues&state=all&group_id=1&language%5B%5D=C&language%5B%5D=JavaScript&label_name%5B%5D=Aftersync&label_name%5B%5D=Brist&search=*',
        );
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
        { clearParams: true },
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
        return testAction(action, undefined, state, expectedMutations, []).then(() => {
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

      expect(mock.history.get).toHaveLength(0);
    });
  });

  describe('fetchSidebarCount uses wild card search', () => {
    beforeEach(() => {
      state.navigation = noActiveItems;
      state.query = { search: '' };
      state.urlQuery = { search: '' };

      jest.spyOn(urlUtils, 'setUrlParams').mockImplementation((params) => {
        return `http://test.host/search/count?search=${params.search || '*'}`;
      });

      storeUtils.skipBlobESCount = jest.fn().mockReturnValue(true);

      mock.onGet().reply(HTTP_STATUS_OK, MOCK_ENDPOINT_RESPONSE);
    });

    it('should use wild card', async () => {
      const commit = jest.fn();

      await actions.fetchSidebarCount({ commit, state });

      expect(urlUtils.setUrlParams).toHaveBeenCalledWith(expect.objectContaining({ search: '*' }), {
        url: expect.anything(),
      });
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
            value: ['Aftersync'],
          },
          type: 'SET_QUERY',
        },
        {
          payload: false,
          type: 'SET_SIDEBAR_DIRTY',
        },
      ];
      return testAction(actions.closeLabel, { title: 'Brist' }, state, expectedResult, []);
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
