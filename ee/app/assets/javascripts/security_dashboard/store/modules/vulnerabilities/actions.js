import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export const fetchVulnerabilitiesCount = ({ state, dispatch }) => {
  dispatch('requestVulnerabilitiesCount');

  axios({
    method: 'GET',
    url: state.vulnerabilitiesCountEndpoint,
  })
    .then(response => {
      const { data } = response;
      dispatch('receiveVulnerabilitiesCountSuccess', { data });
    })
    .catch(() => {
      dispatch('receiveVulnerabilitiesCountError');
    });
};

export const requestVulnerabilitiesCount = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES_COUNT);
};

export const receiveVulnerabilitiesCountSuccess = ({ commit }, response) => {
  commit(types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS, response.data);
};

export const receiveVulnerabilitiesCountError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_COUNT_ERROR);
};

export const fetchVulnerabilities = ({ state, dispatch }, page = 1) => {
  dispatch('requestVulnerabilities');

  axios({
    method: 'GET',
    url: state.vulnerabilitiesEndpoint,
    params: { page },
  })
    .then(response => {
      const { headers, data } = response;
      dispatch('receiveVulnerabilitiesSuccess', { headers, data });
    })
    .catch(() => {
      dispatch('receiveVulnerabilitiesError');
    });
};

export const requestVulnerabilities = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES);
};

export const receiveVulnerabilitiesSuccess = ({ commit }, response = {}) => {
  const normalizedHeaders = normalizeHeaders(response.headers);
  const pageInfo = parseIntPagination(normalizedHeaders);
  const vulnerabilities = response.data;

  commit(types.RECEIVE_VULNERABILITIES_SUCCESS, { pageInfo, vulnerabilities });
};

export const receiveVulnerabilitiesError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_ERROR);
};

export default () => {};
