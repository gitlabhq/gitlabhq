import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import * as actions from '~/header_search/store/actions';
import * as types from '~/header_search/store/mutation_types';
import createState from '~/header_search/store/state';
import axios from '~/lib/utils/axios_utils';
import { MOCK_SEARCH, MOCK_AUTOCOMPLETE_OPTIONS } from '../mock_data';

jest.mock('~/flash');

describe('Header Search Store Actions', () => {
  let state;
  let mock;

  const flashCallback = (callCount) => {
    expect(createFlash).toHaveBeenCalledTimes(callCount);
    createFlash.mockClear();
  };

  beforeEach(() => {
    state = createState({});
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe.each`
    axiosMock                                                         | type         | expectedMutations                                                                                                           | flashCallCount
    ${{ method: 'onGet', code: 200, res: MOCK_AUTOCOMPLETE_OPTIONS }} | ${'success'} | ${[{ type: types.REQUEST_AUTOCOMPLETE }, { type: types.RECEIVE_AUTOCOMPLETE_SUCCESS, payload: MOCK_AUTOCOMPLETE_OPTIONS }]} | ${0}
    ${{ method: 'onGet', code: 500, res: null }}                      | ${'error'}   | ${[{ type: types.REQUEST_AUTOCOMPLETE }, { type: types.RECEIVE_AUTOCOMPLETE_ERROR }]}                                       | ${1}
  `('fetchAutocompleteOptions', ({ axiosMock, type, expectedMutations, flashCallCount }) => {
    describe(`on ${type}`, () => {
      beforeEach(() => {
        mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
      });
      it(`should dispatch the correct mutations`, () => {
        return testAction({
          action: actions.fetchAutocompleteOptions,
          state,
          expectedMutations,
        }).then(() => flashCallback(flashCallCount));
      });
    });
  });

  describe('setSearch', () => {
    it('calls the SET_SEARCH mutation', () => {
      return testAction({
        action: actions.setSearch,
        payload: MOCK_SEARCH,
        state,
        expectedMutations: [{ type: types.SET_SEARCH, payload: MOCK_SEARCH }],
      });
    });
  });
});
