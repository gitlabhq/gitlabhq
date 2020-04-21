import { difference, intersection } from 'lodash';
import {
  STATUS_FAILED,
  STATUS_SUCCESS,
  ACCESSIBILITY_ISSUE_ERROR,
  ACCESSIBILITY_ISSUE_WARNING,
} from '../../constants';

export const parseAccessibilityReport = data => {
  // Combine all issues into one array
  return Object.keys(data.results)
    .map(key => [...data.results[key]])
    .flat()
    .map(issue => JSON.stringify(issue)); // stringify to help with comparisons
};

export const compareAccessibilityReports = reports => {
  const result = {
    status: '',
    summary: {
      total: 0,
      notes: 0,
      errors: 0,
      warnings: 0,
    },
    new_errors: [],
    new_notes: [],
    new_warnings: [],
    resolved_errors: [],
    resolved_notes: [],
    resolved_warnings: [],
    existing_errors: [],
    existing_notes: [],
    existing_warnings: [],
  };

  const headReport = reports.filter(report => report.isHead)[0];
  const baseReport = reports.filter(report => !report.isHead)[0];

  // existing issues are those that exist in both the head report and the base report
  const existingIssues = intersection(headReport.issues, baseReport.issues);
  // new issues are those that exist in only the head report
  const newIssues = difference(headReport.issues, baseReport.issues);
  // resolved issues are those that exist in only the base report
  const resolvedIssues = difference(baseReport.issues, headReport.issues);

  const parseIssues = (issue, issueType, shouldCount) => {
    const parsedIssue = JSON.parse(issue);
    switch (parsedIssue.type) {
      case ACCESSIBILITY_ISSUE_ERROR:
        result[`${issueType}_errors`].push(parsedIssue);
        if (shouldCount) {
          result.summary.errors += 1;
        }
        break;
      case ACCESSIBILITY_ISSUE_WARNING:
        result[`${issueType}_warnings`].push(parsedIssue);
        if (shouldCount) {
          result.summary.warnings += 1;
        }
        break;
      default:
        result[`${issueType}_notes`].push(parsedIssue);
        if (shouldCount) {
          result.summary.notes += 1;
        }
        break;
    }
  };

  existingIssues.forEach(issue => parseIssues(issue, 'existing', true));
  newIssues.forEach(issue => parseIssues(issue, 'new', true));
  resolvedIssues.forEach(issue => parseIssues(issue, 'resolved', false));

  result.summary.total = result.summary.errors + result.summary.warnings + result.summary.notes;
  const hasErrorsOrWarnings = result.summary.errors > 0 || result.summary.warnings > 0;
  result.status = hasErrorsOrWarnings ? STATUS_FAILED : STATUS_SUCCESS;

  return result;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
