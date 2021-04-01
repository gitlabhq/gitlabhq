import { sprintf, n__, s__, __ } from '~/locale';
import {
  STATUS_FAILED,
  STATUS_SUCCESS,
  ICON_WARNING,
  ICON_SUCCESS,
  ICON_NOTFOUND,
} from '../../constants';

const textBuilder = (results) => {
  const { failed, errored, resolved, total } = results;

  const failedOrErrored = (failed || 0) + (errored || 0);
  const failedString = failed ? n__('%d failed', '%d failed', failed) : null;
  const erroredString = errored ? n__('%d error', '%d errors', errored) : null;
  const combinedString =
    failed && errored ? `${failedString}, ${erroredString}` : failedString || erroredString;
  const resolvedString = resolved
    ? n__('%d fixed test result', '%d fixed test results', resolved)
    : null;
  const totalString = total ? n__('out of %d total test', 'out of %d total tests', total) : null;

  let resultsString = s__('Reports|no changed test results');

  if (failedOrErrored) {
    if (resolved) {
      resultsString = sprintf(s__('Reports|%{combinedString} and %{resolvedString}'), {
        combinedString,
        resolvedString,
      });
    } else {
      resultsString = combinedString;
    }
  } else if (resolved) {
    resultsString = resolvedString;
  }

  return `${resultsString} ${totalString}`;
};

export const summaryTextBuilder = (name = '', results = {}) => {
  const resultsString = textBuilder(results);
  return sprintf(__('%{name} contained %{resultsString}'), { name, resultsString });
};

export const reportTextBuilder = (name = '', results = {}) => {
  const resultsString = textBuilder(results);
  return sprintf(__('%{name} found %{resultsString}'), { name, resultsString });
};

export const recentFailuresTextBuilder = (summary = {}) => {
  const { failed, recentlyFailed } = summary;
  if (!failed || !recentlyFailed) return '';

  if (failed < 2) {
    return sprintf(
      s__(
        'Reports|%{recentlyFailed} out of %{failed} failed test has failed more than once in the last 14 days',
      ),
      { recentlyFailed, failed },
    );
  }
  return sprintf(
    n__(
      'Reports|%{recentlyFailed} out of %{failed} failed tests has failed more than once in the last 14 days',
      'Reports|%{recentlyFailed} out of %{failed} failed tests have failed more than once in the last 14 days',
      recentlyFailed,
    ),
    { recentlyFailed, failed },
  );
};

export const countRecentlyFailedTests = (subject) => {
  // handle either a single report or an array of reports
  const reports = !subject.length ? [subject] : subject;

  return reports
    .map((report) => {
      return (
        [report.new_failures, report.existing_failures, report.resolved_failures]
          // only count tests which have failed more than once
          .map(
            (failureArray) =>
              failureArray.filter((failure) => failure.recent_failures?.count > 1).length,
          )
          .reduce((total, count) => total + count, 0)
      );
    })
    .reduce((total, count) => total + count, 0);
};

export const statusIcon = (status) => {
  if (status === STATUS_FAILED) {
    return ICON_WARNING;
  }

  if (status === STATUS_SUCCESS) {
    return ICON_SUCCESS;
  }

  return ICON_NOTFOUND;
};

/**
 * Removes `./` from the beginning of a file path so it can be appended onto a blob path
 * @param {String} file
 * @returns {String}  - formatted value
 */
export const formatFilePath = (file) => {
  return file.replace(/^\.?\/*/, '');
};
