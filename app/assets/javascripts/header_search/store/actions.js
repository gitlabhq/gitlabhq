import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const fetchAutocompleteOptions = ({ commit, getters }) => {
  commit(types.REQUEST_AUTOCOMPLETE);
  return axios
    .get(getters.autocompleteQuery)
    .then(({ data }) => commit(types.RECEIVE_AUTOCOMPLETE_SUCCESS, data))
    .catch(() => {
      commit(types.RECEIVE_AUTOCOMPLETE_ERROR);
      createFlash({ message: __('There was an error fetching search autocomplete suggestions') });
    });
};

export const setSearch = ({ commit }, value) => {
  commit(types.SET_SEARCH, value);
};
