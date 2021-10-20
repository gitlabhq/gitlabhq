import * as types from '~/header_search/store/mutation_types';
import mutations from '~/header_search/store/mutations';
import createState from '~/header_search/store/state';
import { MOCK_SEARCH, MOCK_AUTOCOMPLETE_OPTIONS } from '../mock_data';

describe('Header Search Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({});
  });

  describe('REQUEST_AUTOCOMPLETE', () => {
    it('sets loading to true and empties autocompleteOptions array', () => {
      mutations[types.REQUEST_AUTOCOMPLETE](state);

      expect(state.loading).toBe(true);
      expect(state.autocompleteOptions).toStrictEqual([]);
    });
  });

  describe('RECEIVE_AUTOCOMPLETE_SUCCESS', () => {
    it('sets loading to false and sets autocompleteOptions array', () => {
      mutations[types.RECEIVE_AUTOCOMPLETE_SUCCESS](state, MOCK_AUTOCOMPLETE_OPTIONS);

      expect(state.loading).toBe(false);
      expect(state.autocompleteOptions).toStrictEqual(MOCK_AUTOCOMPLETE_OPTIONS);
    });
  });

  describe('RECEIVE_AUTOCOMPLETE_ERROR', () => {
    it('sets loading to false and empties autocompleteOptions array', () => {
      mutations[types.RECEIVE_AUTOCOMPLETE_ERROR](state);

      expect(state.loading).toBe(false);
      expect(state.autocompleteOptions).toStrictEqual([]);
    });
  });

  describe('SET_SEARCH', () => {
    it('sets search to value', () => {
      mutations[types.SET_SEARCH](state, MOCK_SEARCH);

      expect(state.search).toBe(MOCK_SEARCH);
    });
  });
});
