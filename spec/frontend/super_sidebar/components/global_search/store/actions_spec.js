import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/super_sidebar/components/global_search/store/actions';
import * as types from '~/super_sidebar/components/global_search/store/mutation_types';
import initState from '~/super_sidebar/components/global_search/store/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  MOCK_SEARCH,
  MOCK_AUTOCOMPLETE_OPTIONS_RES,
  MOCK_AUTOCOMPLETE_PATH,
  MOCK_PROJECT,
  MOCK_SEARCH_CONTEXT,
  MOCK_SEARCH_PATH,
  MOCK_MR_PATH,
  MOCK_ISSUE_PATH,
} from '../mock_data';

describe('Global Search Store Actions', () => {
  let state;
  let mock;

  const createState = (initialState) =>
    initState({
      searchPath: MOCK_SEARCH_PATH,
      issuesPath: MOCK_ISSUE_PATH,
      mrPath: MOCK_MR_PATH,
      autocompletePath: MOCK_AUTOCOMPLETE_PATH,
      searchContext: MOCK_SEARCH_CONTEXT,
      ...initialState,
    });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe.each`
    axiosMock                                                                        | type         | expectedMutations
    ${{ method: 'onGet', code: HTTP_STATUS_OK, res: MOCK_AUTOCOMPLETE_OPTIONS_RES }} | ${'success'} | ${[{ type: types.REQUEST_AUTOCOMPLETE }, { type: types.RECEIVE_AUTOCOMPLETE_SUCCESS, payload: MOCK_AUTOCOMPLETE_OPTIONS_RES }, { type: types.RECEIVE_AUTOCOMPLETE_SUCCESS, payload: MOCK_AUTOCOMPLETE_OPTIONS_RES }]}
    ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }}       | ${'error'}   | ${[{ type: types.REQUEST_AUTOCOMPLETE }, { type: types.RECEIVE_AUTOCOMPLETE_ERROR }, { type: types.RECEIVE_AUTOCOMPLETE_ERROR }]}
  `('fetchAutocompleteOptions', ({ axiosMock, type, expectedMutations }) => {
    describe(`on ${type}`, () => {
      beforeEach(() => {
        state = createState({});
        mock = new MockAdapter(axios);
        mock[axiosMock.method]().reply(axiosMock.code, axiosMock.res);
      });
      it(`should dispatch the correct mutations`, () => {
        return testAction({
          action: actions.fetchAutocompleteOptions,
          state,
          expectedMutations,
        });
      });
    });
  });

  describe.each`
    project         | ref                | fetchType    | expectedPath
    ${null}         | ${null}            | ${null}      | ${`${MOCK_AUTOCOMPLETE_PATH}?term=${MOCK_SEARCH}`}
    ${MOCK_PROJECT} | ${null}            | ${'generic'} | ${`${MOCK_AUTOCOMPLETE_PATH}?term=${MOCK_SEARCH}&project_id=${MOCK_PROJECT.id}&filter=generic`}
    ${null}         | ${MOCK_PROJECT.id} | ${'generic'} | ${`${MOCK_AUTOCOMPLETE_PATH}?term=${MOCK_SEARCH}&project_ref=${MOCK_PROJECT.id}&filter=generic`}
    ${MOCK_PROJECT} | ${MOCK_PROJECT.id} | ${'search'}  | ${`${MOCK_AUTOCOMPLETE_PATH}?term=${MOCK_SEARCH}&project_id=${MOCK_PROJECT.id}&project_ref=${MOCK_PROJECT.id}&filter=search`}
  `('autocompleteQuery', ({ project, ref, fetchType, expectedPath }) => {
    describe(`when project is ${project?.name} and project ref is ${ref}`, () => {
      beforeEach(() => {
        state = createState({
          search: MOCK_SEARCH,
          searchContext: {
            project,
            ref,
          },
        });
      });

      it(`should return ${expectedPath}`, () => {
        expect(actions.autocompleteQuery({ state, fetchType })).toBe(expectedPath);
      });
    });
  });

  describe('clearAutocomplete', () => {
    beforeEach(() => {
      state = createState({});
    });

    it('calls the CLEAR_AUTOCOMPLETE mutation', () => {
      return testAction({
        action: actions.clearAutocomplete,
        state,
        expectedMutations: [{ type: types.CLEAR_AUTOCOMPLETE }],
      });
    });
  });

  describe('setSearch', () => {
    beforeEach(() => {
      state = createState({});
    });

    it('calls the SET_SEARCH mutation', () => {
      return testAction({
        action: actions.setSearch,
        payload: MOCK_SEARCH,
        state,
        expectedMutations: [{ type: types.SET_SEARCH, payload: MOCK_SEARCH }],
      });
    });
  });
  describe('setCommand', () => {
    beforeEach(() => {
      state = createState({});
    });

    it('calls the SET_COMMAND mutation', () => {
      return testAction({
        action: actions.setCommand,
        payload: '>',
        state,
        expectedMutations: [{ type: types.SET_COMMAND, payload: '>' }],
      });
    });
  });
});
