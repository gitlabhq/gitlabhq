import { LOADING, ERROR, SUCCESS, STATUS_FAILED } from '../../constants';
import { s__, n__ } from '~/locale';

export const groupedSummaryText = state => {
  if (state.isLoading) {
    return s__('Reports|Accessibility scanning results are being parsed');
  }

  if (state.hasError) {
    return s__('Reports|Accessibility scanning failed loading results');
  }

  const numberOfResults =
    (state.report?.summary?.errors || 0) + (state.report?.summary?.warnings || 0);
  if (numberOfResults === 0) {
    return s__('Reports|Accessibility scanning detected no issues for the source branch only');
  }

  return n__(
    'Reports|Accessibility scanning detected %d issue for the source branch only',
    'Reports|Accessibility scanning detected %d issues for the source branch only',
    numberOfResults,
  );
};

export const summaryStatus = state => {
  if (state.isLoading) {
    return LOADING;
  }

  if (state.hasError || state.status === STATUS_FAILED) {
    return ERROR;
  }

  return SUCCESS;
};

export const shouldRenderIssuesList = state =>
  Object.values(state.report).some(x => Array.isArray(x) && x.length > 0);

export const unresolvedIssues = state => [
  ...state.report.existing_errors,
  ...state.report.existing_warnings,
  ...state.report.existing_notes,
];

export const resolvedIssues = state => [
  ...state.report.resolved_errors,
  ...state.report.resolved_warnings,
  ...state.report.resolved_notes,
];

export const newIssues = state => [
  ...state.report.new_errors,
  ...state.report.new_warnings,
  ...state.report.new_notes,
];

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
