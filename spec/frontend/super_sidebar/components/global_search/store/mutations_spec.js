import * as types from '~/super_sidebar/components/global_search/store/mutation_types';
import mutations from '~/super_sidebar/components/global_search/store/mutations';
import createState from '~/super_sidebar/components/global_search/store/state';
import {
  MOCK_SEARCH,
  MOCK_AUTOCOMPLETE_OPTIONS_RES,
  MOCK_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

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
      expect(state.autocompleteError).toBe(false);
    });
  });

  describe('RECEIVE_AUTOCOMPLETE_SUCCESS', () => {
    it('sets loading to false and then formats and sets the autocompleteOptions array', () => {
      mutations[types.RECEIVE_AUTOCOMPLETE_SUCCESS](state, MOCK_AUTOCOMPLETE_OPTIONS_RES);

      expect(state.loading).toBe(false);
      expect(state.autocompleteOptions).toEqual(MOCK_AUTOCOMPLETE_OPTIONS);
      expect(state.autocompleteError).toBe(false);
    });
  });

  describe('RECEIVE_AUTOCOMPLETE_ERROR', () => {
    it('sets loading to false and empties autocompleteOptions array', () => {
      mutations[types.RECEIVE_AUTOCOMPLETE_ERROR](state);

      expect(state.loading).toBe(false);
      expect(state.autocompleteOptions).toStrictEqual([]);
      expect(state.autocompleteError).toBe(true);
    });
  });

  describe('CLEAR_AUTOCOMPLETE', () => {
    it('empties autocompleteOptions array', () => {
      mutations[types.CLEAR_AUTOCOMPLETE](state);

      expect(state.autocompleteOptions).toStrictEqual([]);
      expect(state.autocompleteError).toBe(false);
    });
  });

  describe('SET_SEARCH', () => {
    it('sets search to value', () => {
      mutations[types.SET_SEARCH](state, MOCK_SEARCH);

      expect(state.search).toBe(MOCK_SEARCH);
    });
  });

  describe('SET_COMMAND', () => {
    it('sets search to value', () => {
      mutations[types.SET_COMMAND](state, '>');

      expect(state.commandChar).toBe('>');
    });
  });
});
