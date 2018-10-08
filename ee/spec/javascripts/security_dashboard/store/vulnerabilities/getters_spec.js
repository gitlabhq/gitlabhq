import State from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as getters from 'ee/security_dashboard/store/modules/vulnerabilities/getters';

describe('vulnerabilities module getters', () => {
  const initialState = State();
  describe('vulnerabilitiesCountBySeverity', () => {
    const sast = { critical: 10 };
    const dast = { critical: 66 };
    const expectedValue = sast.critical + dast.critical;
    const vulnerabilitiesCount = { sast, dast };
    const state = { vulnerabilitiesCount };

    it('should add up all the counts with `high` severity', () => {
      const result = getters.vulnerabilitiesCountBySeverity(state)('critical');

      expect(result).toBe(expectedValue);
    });

    it('should return 0 if no counts match the severity name', () => {
      const result = getters.vulnerabilitiesCountBySeverity(state)('medium');

      expect(result).toBe(0);
    });

    it('should return 0 if there are no counts at all', () => {
      const result = getters.vulnerabilitiesCountBySeverity(initialState)('critical');

      expect(result).toBe(0);
    });
  });

  describe('vulnerabilitiesCountByReportType', () => {
    const sast = { critical: 10, medium: 22 };
    const dast = { critical: 66 };
    const expectedValue = sast.critical + sast.medium;
    const vulnerabilitiesCount = { sast, dast };
    const state = { vulnerabilitiesCount };

    it('should add up all the counts in the sast report', () => {
      const result = getters.vulnerabilitiesCountByReportType(state)('sast');

      expect(result).toBe(expectedValue);
    });

    it('should return 0 if there are no reports for a severity type', () => {
      const result = getters.vulnerabilitiesCountByReportType(initialState)('sast');

      expect(result).toBe(0);
    });
  });
});
