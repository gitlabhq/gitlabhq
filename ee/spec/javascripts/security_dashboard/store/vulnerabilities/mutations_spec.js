import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/vulnerabilities/mutations';

describe('vulnerabilities module mutations', () => {
  describe('SET_PAGINATION', () => {
    it('should apply the payload to `pageInfo` in the state', () => {
      const state = initialState;
      const payload = { page: 2 };

      mutations[types.SET_PAGINATION](state, payload);

      expect(state.pageInfo).toEqual(payload);
    });
  });

  describe('SET_VULNERABILITIES', () => {
    it('should apply the payload to `pageInfo` in the state', () => {
      const state = initialState;
      const payload = [1, 2, 3, 4, 5];

      mutations[types.SET_VULNERABILITIES](state, payload);

      expect(state.vulnerabilities).toEqual(payload);
    });
  });

  describe('SET_LOADING', () => {
    it('should set loading to true', () => {
      const state = initialState;

      mutations[types.SET_LOADING](state, true);

      expect(state.isLoading).toBeTruthy();
    });

    it('should not modify loading values are the same', () => {
      const state = initialState;

      mutations[types.SET_LOADING](state, false);

      expect(state.isLoading).toBeFalsy();
    });
  });
});
