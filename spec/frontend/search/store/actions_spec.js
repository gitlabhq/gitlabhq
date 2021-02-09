import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import * as actions from '~/search/store/actions';
import * as types from '~/search/store/mutation_types';
import * as urlUtils from '~/lib/utils/url_utility';
import createState from '~/search/store/state';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECT,
  MOCK_PROJECTS,
  MOCK_SEARCH_COUNT,
  MOCK_SEARCH_COUNTS_SUCCESS,
  MOCK_SEARCH_COUNTS_INPUT,
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

  const noCallback = () => {};
  const flashCallback = () => {
    expect(createFlash).toHaveBeenCalledTimes(1);
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
    action                       | axiosMock                                                 | payload                     | type         | expectedMutations                                                                                                                                                 | callback
    ${actions.fetchGroups}       | ${{ method: 'onGet', code: 200, res: MOCK_GROUPS }}       | ${null}                     | ${'success'} | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_SUCCESS, payload: MOCK_GROUPS }]}                                                                 | ${noCallback}
    ${actions.fetchGroups}       | ${{ method: 'onGet', code: 500, res: null }}              | ${null}                     | ${'error'}   | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_ERROR }]}                                                                                         | ${flashCallback}
    ${actions.fetchProjects}     | ${{ method: 'onGet', code: 200, res: MOCK_PROJECTS }}     | ${null}                     | ${'success'} | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_SUCCESS, payload: MOCK_PROJECTS }]}                                                           | ${noCallback}
    ${actions.fetchProjects}     | ${{ method: 'onGet', code: 500, res: null }}              | ${null}                     | ${'error'}   | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_ERROR }]}                                                                                     | ${flashCallback}
    ${actions.fetchSearchCounts} | ${{ method: 'onGet', code: 200, res: MOCK_SEARCH_COUNT }} | ${MOCK_SEARCH_COUNTS_INPUT} | ${'success'} | ${[{ type: types.REQUEST_SEARCH_COUNTS, payload: MOCK_SEARCH_COUNTS_INPUT }, { type: types.RECEIVE_SEARCH_COUNTS_SUCCESS, payload: MOCK_SEARCH_COUNTS_SUCCESS }]} | ${noCallback}
    ${actions.fetchSearchCounts} | ${{ method: 'onGet', code: 500, res: null }}              | ${MOCK_SEARCH_COUNTS_INPUT} | ${'error'}   | ${[{ type: types.REQUEST_SEARCH_COUNTS, payload: MOCK_SEARCH_COUNTS_INPUT }]}                                                                                     | ${flashCallback}
  `(`axios calls`, ({ action, axiosMock, payload, type, expectedMutations, callback }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().reply(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction({ action, payload, state, expectedMutations }).then(() => callback());
        });
      });
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

        expect(Api.groupProjects).toHaveBeenCalled();
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
          nav_source: null,
        });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  it('calls setUrlParams with snippets, group_id, and project_id when snippets param is true', () => {
    return testAction(actions.resetQuery, true, state, [], [], () => {
      expect(urlUtils.setUrlParams).toHaveBeenCalledWith({
        ...state.query,
        page: null,
        state: null,
        confidential: null,
        nav_source: null,
        group_id: null,
        project_id: null,
        snippets: true,
      });
    });
  });
});
