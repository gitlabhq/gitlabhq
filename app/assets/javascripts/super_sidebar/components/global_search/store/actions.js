import { omitBy, isNil } from 'lodash';
import { objectToQuery } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { FETCH_TYPES } from '../constants';
import * as types from './mutation_types';

export const autocompleteQuery = ({ state, fetchType }) => {
  const query = omitBy(
    {
      term: state.search,
      project_id: state.searchContext?.project?.id,
      project_ref: state.searchContext?.ref,
      filter: fetchType,
    },
    isNil,
  );

  return `${state.autocompletePath}?${objectToQuery(query)}`;
};

const doFetch = ({ commit, state, fetchType }) => {
  return axios
    .get(autocompleteQuery({ state, fetchType }))
    .then(({ data }) => {
      commit(types.RECEIVE_AUTOCOMPLETE_SUCCESS, data);
    })
    .catch(() => {
      commit(types.RECEIVE_AUTOCOMPLETE_ERROR);
    });
};

export const fetchAutocompleteOptions = ({ commit, state }) => {
  commit(types.REQUEST_AUTOCOMPLETE);
  const promises = FETCH_TYPES.map((fetchType) => doFetch({ commit, state, fetchType }));

  return Promise.all(promises);
};

export const clearAutocomplete = ({ commit }) => {
  commit(types.CLEAR_AUTOCOMPLETE);
};

export const setSearch = ({ commit }, value) => {
  commit(types.SET_SEARCH, value);
};

export const setCommand = ({ commit }, value) => {
  commit(types.SET_COMMAND, value);
};
