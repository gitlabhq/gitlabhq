import * as types from './mutation_types';
import mockData from './mock_data.json';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export const fetchVulnerabilities = ({ dispatch }, params = {}) => {
  dispatch('requestVulnerabilities');

  // TODO: Replace with axios when we can use the actual API
  Promise.resolve({
    data: mockData,
    headers: {
      'X-Page': params.page || 1,
      'X-Next-Page': 2,
      'X-Prev-Page': 1,
      'X-Per-Page': 20,
      'X-Total': 100,
      'X-Total-Pages': 5,
    } })
    .then(response => {
      dispatch('receiveVulnerabilitiesSuccess', response);
    })
    .catch(error => {
      dispatch('receiveVulnerabilitiesError', error);
    });
};

export const requestVulnerabilities = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveVulnerabilitiesSuccess = ({ commit }, response = {}) => {
  const normalizedHeaders = normalizeHeaders(response.headers);
  const paginationInformation = parseIntPagination(normalizedHeaders);

  commit(types.SET_LOADING, false);
  commit(types.SET_VULNERABILITIES, response.data);
  commit(types.SET_PAGINATION, paginationInformation);
};

export const receiveVulnerabilitiesError = ({ commit }) => {
  // TODO: Show error state when we get it from UX
  commit(types.SET_LOADING, false);
};

export default () => {};
