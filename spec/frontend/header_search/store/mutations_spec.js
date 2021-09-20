import * as types from '~/header_search/store/mutation_types';
import mutations from '~/header_search/store/mutations';
import createState from '~/header_search/store/state';
import { MOCK_SEARCH } from '../mock_data';

describe('Header Search Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({});
  });

  describe('SET_SEARCH', () => {
    it('sets search to value', () => {
      mutations[types.SET_SEARCH](state, MOCK_SEARCH);

      expect(state.search).toBe(MOCK_SEARCH);
    });
  });
});
