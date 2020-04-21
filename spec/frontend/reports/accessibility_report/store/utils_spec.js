import * as utils from '~/reports/accessibility_report/store/utils';
import { baseReport, headReport, parsedBaseReport, comparedReportResult } from '../mock_data';

describe('Accessibility Report store utils', () => {
  describe('parseAccessibilityReport', () => {
    it('returns array of stringified issues', () => {
      const result = utils.parseAccessibilityReport(baseReport);

      expect(result).toEqual(parsedBaseReport);
    });
  });

  describe('compareAccessibilityReports', () => {
    let reports;

    beforeEach(() => {
      reports = [
        {
          isHead: false,
          issues: utils.parseAccessibilityReport(baseReport),
        },
        {
          isHead: true,
          issues: utils.parseAccessibilityReport(headReport),
        },
      ];
    });

    it('returns the comparison report with a new, resolved, and existing error', () => {
      const result = utils.compareAccessibilityReports(reports);

      expect(result).toEqual(comparedReportResult);
    });
  });
});
