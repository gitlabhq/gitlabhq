import { __, n__, s__, sprintf } from '~/locale';

const digitText = (bold = false) => (bold ? '%{strong_start}%d%{strong_end}' : '%d');
const noText = (bold = false) => (bold ? '%{strong_start}no%{strong_end}' : 'no');

export const TESTS_FAILED_STATUS = 'failed';
export const ERROR_STATUS = 'error';

export const i18n = {
  label: s__('Reports|Test summary'),
  loading: s__('Reports|Test summary results are loading'),
  error: s__('Reports|Test summary failed to load results'),
  fullReport: s__('Reports|Full report'),

  noChanges: (bold) => s__(`Reports|${noText(bold)} changed test results`),
  resultsString: (combinedString, resolvedString) =>
    sprintf(s__('Reports|%{combinedString} and %{resolvedString}'), {
      combinedString,
      resolvedString,
    }),

  summaryText: (name, resultsString) =>
    sprintf(__('%{name}: %{resultsString}'), { name, resultsString }),

  failedClause: (failed, bold) =>
    n__(`${digitText(bold)} failed`, `${digitText(bold)} failed`, failed),
  erroredClause: (errored, bold) =>
    n__(`${digitText(bold)} error`, `${digitText(bold)} errors`, errored),
  resolvedClause: (resolved, bold) =>
    n__(`${digitText(bold)} fixed test result`, `${digitText(bold)} fixed test results`, resolved),
  totalClause: (total, bold) =>
    n__(`${digitText(bold)} total test`, `${digitText(bold)} total tests`, total),

  reportError: s__('Reports|An error occurred while loading report'),
  reportErrorWithName: (name) =>
    sprintf(s__('Reports|An error occurred while loading %{name} results'), { name }),
  headReportParsingError: s__('Reports|Head report parsing error:'),
  baseReportParsingError: s__('Reports|Base report parsing error:'),
};
