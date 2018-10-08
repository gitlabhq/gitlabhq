import * as types from './mutation_types';

export default {
  [types.REQUEST_VULNERABILITIES](state) {
    state.isLoadingVulnerabilities = true;
  },
  [types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload) {
    state.isLoadingVulnerabilities = false;
    state.errorLoadingVulnerabilities = false;
    state.pageInfo = payload.pageInfo;
    state.vulnerabilities = payload.vulnerabilities;
  },
  [types.RECEIVE_VULNERABILITIES_ERROR](state) {
    state.isLoadingVulnerabilities = false;
    state.errorLoadingVulnerabilities = true;
  },
  [types.REQUEST_VULNERABILITIES_COUNT](state) {
    state.isLoadingVulnerabilitiesCount = true;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload) {
    state.isLoadingVulnerabilitiesCount = false;
    state.errorLoadingVulnerabilities = false;
    state.vulnerabilitiesCount = payload;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state) {
    state.isLoadingVulnerabilitiesCount = false;
    state.errorLoadingVulnerabilities = true;
  },
};
