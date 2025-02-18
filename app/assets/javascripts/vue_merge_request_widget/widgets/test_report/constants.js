import { __, n__, s__, sprintf } from '~/locale';

const digitText = ({ digit, bold = false } = {}) =>
  bold ? `%{strong_start}${digit}%{strong_end}` : digit;
const noText = (bold = false) => (bold ? __('%{strong_start}no%{strong_end}') : __('no'));

export const TESTS_FAILED_STATUS = 'failed';
export const ERROR_STATUS = 'error';

export const i18n = {
  copyFailedSpecs: s__('Reports|Copy failed tests'),
  copyFailedSpecsTooltip: s__('Reports|Copy failed test names to run locally'),
  label: s__('Reports|Test summary'),
  loading: s__('Reports|Test summary results are being parsed'),
  error: s__('Reports|Test summary failed to load results'),
  newHeader: s__('Reports|New'),
  fixedHeader: s__('Reports|Fixed'),
  fullReport: s__('Reports|Full report'),
  partialReport: s__('Reports|View partial report'),
  partialReportTooltipText: s__('Reports|See test results while the pipeline is running'),

  noChanges: (bold) => sprintf(s__('Reports|%{no} changed test results'), { no: noText(bold) }),
  resultsString: (combinedString, resolvedString) =>
    sprintf(s__('Reports|%{combinedString} and %{resolvedString}'), {
      combinedString,
      resolvedString,
    }),

  summaryText: (name, resultsString) =>
    sprintf(__('%{name}: %{resultsString}'), { name, resultsString }),

  failedClause: (failed, bold) =>
    sprintf(n__('%{digit} failed', '%{digit} failed', failed), {
      digit: digitText({ digit: failed, bold }),
    }),
  erroredClause: (errored, bold) =>
    sprintf(n__('%{digit} error', '%{digit} errors', errored), {
      digit: digitText({ digit: errored, bold }),
    }),
  resolvedClause: (resolved, bold) =>
    sprintf(n__('%{digit} fixed test result', '%{digit} fixed test results', resolved), {
      digit: digitText({ digit: resolved, bold }),
    }),
  totalClause: (total, bold) =>
    sprintf(n__('%{digit} total test', '%{digit} total tests', total), {
      digit: digitText({ digit: total, bold }),
    }),

  reportError: s__('Reports|An error occurred while loading report'),
  reportErrorWithName: (name) =>
    sprintf(s__('Reports|An error occurred while loading %{name} results'), { name }),
  headReportParsingError: s__('Reports|Head report parsing error:'),
  baseReportParsingError: s__('Reports|Base report parsing error:'),

  recentFailureSummary: (recentlyFailed, failed) => {
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
  },
  recentFailureCount: (recentFailures) =>
    sprintf(
      n__(
        'Reports|Failed %{count} time in %{base_branch} in the last 14 days',
        'Reports|Failed %{count} times in %{base_branch} in the last 14 days',
        recentFailures.count,
      ),
      recentFailures,
    ),
};
