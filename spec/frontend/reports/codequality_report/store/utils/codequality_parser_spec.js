import { reportIssues, parsedReportIssues } from 'jest/reports/codequality_report/mock_data';
import { parseCodeclimateMetrics } from '~/reports/codequality_report/store/utils/codequality_parser';

describe('Codequality report store utils', () => {
  let result;

  describe('parseCodeclimateMetrics', () => {
    it('should parse the issues from backend codequality diff', () => {
      [result] = parseCodeclimateMetrics(reportIssues.new_errors, 'path');

      expect(result.name).toEqual(parsedReportIssues.newIssues[0].name);
      expect(result.path).toEqual(parsedReportIssues.newIssues[0].path);
      expect(result.line).toEqual(parsedReportIssues.newIssues[0].line);
    });

    describe('when an issue has no location or path', () => {
      const issue = { description: 'Insecure Dependency' };

      beforeEach(() => {
        [result] = parseCodeclimateMetrics([issue], 'path');
      });

      it('is parsed', () => {
        expect(result.name).toEqual(issue.description);
      });
    });

    describe('when an issue has a path but no line', () => {
      const issue = { description: 'Insecure Dependency', location: { path: 'Gemfile.lock' } };

      beforeEach(() => {
        [result] = parseCodeclimateMetrics([issue], 'path');
      });

      it('is parsed', () => {
        expect(result.name).toEqual(issue.description);
        expect(result.path).toEqual(issue.location.path);
        expect(result.urlPath).toEqual(`path/${issue.location.path}`);
      });
    });

    describe('when an issue has a line nested in positions', () => {
      const issue = {
        description: 'Insecure Dependency',
        location: {
          path: 'Gemfile.lock',
          positions: { begin: { line: 84 } },
        },
      };

      beforeEach(() => {
        [result] = parseCodeclimateMetrics([issue], 'path');
      });

      it('is parsed', () => {
        expect(result.name).toEqual(issue.description);
        expect(result.path).toEqual(issue.location.path);
        expect(result.urlPath).toEqual(
          `path/${issue.location.path}#L${issue.location.positions.begin.line}`,
        );
      });
    });

    describe('with an empty issue array', () => {
      beforeEach(() => {
        result = parseCodeclimateMetrics([], 'path');
      });

      it('returns an empty array', () => {
        expect(result).toEqual([]);
      });
    });
  });
});
