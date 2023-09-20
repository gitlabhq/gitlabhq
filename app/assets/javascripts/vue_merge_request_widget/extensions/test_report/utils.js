import { isEmpty } from 'lodash';
import { i18n } from './constants';

const textBuilder = (results, boldNumbers = false) => {
  const { failed, errored, resolved, total } = results;

  const failedOrErrored = (failed || 0) + (errored || 0);
  const failedString = failed ? i18n.failedClause(failed, boldNumbers) : null;
  const erroredString = errored ? i18n.erroredClause(errored, boldNumbers) : null;
  const combinedString =
    failed && errored ? `${failedString}, ${erroredString}` : failedString || erroredString;
  const resolvedString = resolved ? i18n.resolvedClause(resolved, boldNumbers) : null;
  const totalString = total ? i18n.totalClause(total, boldNumbers) : null;

  let resultsString = i18n.noChanges(boldNumbers);

  if (failedOrErrored) {
    if (resolved) {
      resultsString = i18n.resultsString(combinedString, resolvedString);
    } else {
      resultsString = combinedString;
    }
  } else if (resolved) {
    resultsString = resolvedString;
  }

  return `${resultsString}, ${totalString}`;
};

export const summaryTextBuilder = (name = '', results = {}) => {
  const resultsString = textBuilder(results, true);
  return i18n.summaryText(name, resultsString);
};

export const reportTextBuilder = ({ name = '', summary = {}, status }) => {
  if (!name) {
    return i18n.reportError;
  }
  if (status === 'error') {
    return i18n.reportErrorWithName(name);
  }

  const resultsString = textBuilder(summary);
  return i18n.summaryText(name, resultsString);
};

export const recentFailuresTextBuilder = (summary = {}) => {
  const { failed, recentlyFailed } = summary;
  if (!failed || !recentlyFailed) return '';

  return i18n.recentFailureSummary(recentlyFailed, failed);
};

export const reportSubTextBuilder = ({ suite_errors: suiteErrors, summary }) => {
  if (suiteErrors?.head || suiteErrors?.base) {
    const errors = [];
    if (suiteErrors?.head) {
      errors.push(`${i18n.headReportParsingError} ${suiteErrors.head}`);
    }
    if (suiteErrors?.base) {
      errors.push(`${i18n.baseReportParsingError} ${suiteErrors.base}`);
    }
    return errors;
  }
  return [recentFailuresTextBuilder(summary)];
};

export const countRecentlyFailedTests = (subject) => {
  // return 0 count if subject is [], null, or undefined
  if (isEmpty(subject)) {
    return 0;
  }

  // handle either a single report or an array of reports
  const reports = !subject.length ? [subject] : subject;

  return reports
    .map((report) => {
      return (
        [report.new_failures, report.existing_failures, report.resolved_failures]
          // only count tests which have failed more than once
          .map((failureArray) => {
            if (!failureArray) return 0;
            return failureArray.filter((failure) => failure.recent_failures?.count > 1).length;
          })
          .reduce((total, count) => total + count, 0)
      );
    })
    .reduce((total, count) => total + count, 0);
};

/**
 * Removes `./` from the beginning of a file path so it can be appended onto a blob path
 * @param {String} file
 * @returns {String}  - formatted value
 */
export const formatFilePath = (file) => {
  return file.replace(/^\.?\/*/, '');
};
