import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as getters from 'ee/security_dashboard/store/modules/vulnerabilities/getters';

describe('vulnerabilities module getters', () => {
  describe('vulnerabilities', () => {
    it('should get the vulnerabilities from the state', () => {
      const vulnerabilities = [1, 2, 3, 4, 5];
      const state = { vulnerabilities };
      const result = getters.vulnerabilities(state);

      expect(result).toBe(vulnerabilities);
    });

    it('should get an empty array when there are no vulnerabilities in the state', () => {
      const result = getters.vulnerabilities(initialState);

      expect(result).toEqual([]);
    });
  });

  describe('pageInfo', () => {
    it('should get the pageInfo object from the state', () => {
      const pageInfo = { page: 1 };
      const state = { pageInfo };
      const result = getters.pageInfo(state);

      expect(result).toBe(pageInfo);
    });
  });
});
