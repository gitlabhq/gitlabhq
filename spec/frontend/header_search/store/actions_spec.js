import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/header_search/store/actions';
import * as types from '~/header_search/store/mutation_types';
import createState from '~/header_search/store/state';
import { MOCK_SEARCH } from '../mock_data';

describe('Header Search Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState({});
  });

  afterEach(() => {
    state = null;
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
