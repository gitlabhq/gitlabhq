import { s__, sprintf } from '~/locale';
import { countVulnerabilities, groupedTextBuilder } from './utils';
import { LOADING, ERROR, SUCCESS } from '~/reports/constants';
import { TRANSLATION_IS_LOADING } from './messages';

export const summaryCounts = state =>
  countVulnerabilities(
    state.reportTypes.reduce((acc, reportType) => {
      acc.push(...state[reportType].newIssues);
      return acc;
    }, []),
  );

export const groupedSummaryText = (state, getters) => {
  const reportType = s__('ciReport|Security scanning');
  let status = '';

  // All reports are loading
  if (getters.areAllReportsLoading) {
    return { message: sprintf(TRANSLATION_IS_LOADING, { reportType }) };
  }

  // All reports returned error
  if (getters.allReportsHaveError) {
    return { message: s__('ciReport|Security scanning failed loading any results') };
  }

  if (getters.areReportsLoading && getters.anyReportHasError) {
    status = s__('ciReport|is loading, errors when loading results');
  } else if (getters.areReportsLoading && !getters.anyReportHasError) {
    status = s__('ciReport|is loading');
  } else if (!getters.areReportsLoading && getters.anyReportHasError) {
    status = s__('ciReport|: Loading resulted in an error');
  }

  const { critical, high, other } = getters.summaryCounts;

  return groupedTextBuilder({ reportType, status, critical, high, other });
};

export const summaryStatus = (state, getters) => {
  if (getters.areReportsLoading) {
    return LOADING;
  }

  if (getters.anyReportHasError || getters.anyReportHasIssues) {
    return ERROR;
  }

  return SUCCESS;
};

export const areReportsLoading = state =>
  state.reportTypes.some(reportType => state[reportType].isLoading);

export const areAllReportsLoading = state =>
  state.reportTypes.every(reportType => state[reportType].isLoading);

export const allReportsHaveError = state =>
  state.reportTypes.every(reportType => state[reportType].hasError);

export const anyReportHasError = state =>
  state.reportTypes.some(reportType => state[reportType].hasError);

export const anyReportHasIssues = state =>
  state.reportTypes.some(reportType => state[reportType].newIssues.length > 0);
