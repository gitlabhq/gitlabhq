import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/vulnerabilities/mutations';

describe('vulnerabilities module mutations', () => {
  describe('REQUEST_VULNERABILITIES', () => {
    it('should set `isLoadingVulnerabilities` to `true`', () => {
      const state = initialState;

      mutations[types.REQUEST_VULNERABILITIES](state);

      expect(state.isLoadingVulnerabilities).toBeTruthy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = {
        vulnerabilities: [1, 2, 3, 4, 5],
        pageInfo: { a: 1, b: 2, c: 3 },
      };
      state = initialState;
      mutations[types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilities` to `false`', () => {
      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });

    it('should set `errorLoadingData` to `false`', () => {
      expect(state.errorLoadingData).toBeFalsy();
    });

    it('should set `pageInfo`', () => {
      expect(state.pageInfo).toBe(payload.pageInfo);
    });

    it('should set `vulnerabilities`', () => {
      expect(state.vulnerabilities).toBe(payload.vulnerabilities);
    });
  });

  describe('RECEIVE_VULNERABILITIES_ERROR', () => {
    it('should set `isLoadingVulnerabilities` to `false`', () => {
      const state = initialState;

      mutations[types.RECEIVE_VULNERABILITIES_ERROR](state);

      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });
  });

  describe('REQUEST_VULNERABILITIES_COUNT', () => {
    it('should set `isLoadingVulnerabilitiesCount` to `true`', () => {
      const state = initialState;

      mutations[types.REQUEST_VULNERABILITIES_COUNT](state);

      expect(state.isLoadingVulnerabilitiesCount).toBeTruthy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = { a: 1, b: 2, c: 3 };
      state = initialState;
      mutations[types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilitiesCount` to `false`', () => {
      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });

    it('should set `errorLoadingData` to `false`', () => {
      expect(state.errorLoadingData).toBeFalsy();
    });

    it('should set `vulnerabilitiesCount`', () => {
      expect(state.vulnerabilitiesCount).toBe(payload);
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_ERROR', () => {
    it('should set `isLoadingVulnerabilitiesCount` to `false`', () => {
      const state = initialState;

      mutations[types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state);

      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });
  });
});
