import { n__, s__ } from '~/locale';
import { textBuilder, statusIcon } from './utils';
import { LOADING, ERROR, SUCCESS } from './constants';

export const groupedSastText = ({ sast }) => {
  if (sast.hasError) {
    return s__('ciReport|SAST resulted in error while loading results');
  }

  if (sast.isLoading) {
    return s__('ciReport|SAST is loading');
  }

  return textBuilder(
    'SAST',
    sast.paths,
    sast.newIssues.length,
    sast.resolvedIssues.length,
    sast.allIssues.length,
  );
};

export const groupedSastContainerText = ({ sastContainer }) => {
  if (sastContainer.hasError) {
    return s__('ciReport|Container scanning resulted in error while loading results');
  }

  if (sastContainer.isLoading) {
    return s__('ciReport|Container scanning is loading');
  }

  return textBuilder(
    'Container scanning',
    sastContainer.paths,
    sastContainer.newIssues.length,
    sastContainer.resolvedIssues.length,
  );
};

export const groupedDastText = ({ dast }) => {
  if (dast.hasError) {
    return s__('ciReport|DAST resulted in error while loading results');
  }

  if (dast.isLoading) {
    return s__('ciReport|DAST is loading');
  }

  return textBuilder('DAST', dast.paths, dast.newIssues.length, dast.resolvedIssues.length);
};

export const groupedDependencyText = ({ dependencyScanning }) => {
  if (dependencyScanning.hasError) {
    return s__('ciReport|Dependency scanning resulted in error while loading results');
  }

  if (dependencyScanning.isLoading) {
    return s__('ciReport|Dependency scanning is loading');
  }

  return textBuilder(
    'Dependency scanning',
    dependencyScanning.paths,
    dependencyScanning.newIssues.length,
    dependencyScanning.resolvedIssues.length,
    dependencyScanning.allIssues.length,
  );
};

export const groupedSummaryText = (state, getters) => {
  const { added, fixed } = state.summaryCounts;

  // All reports are loading
  if (getters.areAllReportsLoading) {
    return s__('ciReport|Security scanning is loading');
  }

  // All reports returned error
  if (getters.allReportsHaveError) {
    return s__('ciReport|Security scanning failed loading any results');
  }

  // No base is present in any report
  if (getters.noBaseInAllReports) {
    if (added > 0) {
      return n__(
        'Security scanning detected %d vulnerability for the source branch only',
        'Security scanning detected %d vulnerabilities for the source branch only',
        added,
      );
    }

    return s__(
      'Security scanning detected no vulnerabilities for the source branch only',
    );
  }

  const text = [s__('ciReport|Security scanning')];

  if (getters.areReportsLoading && getters.anyReportHasError) {
    text.push('(is loading, errors when loading results)');
  } else if (getters.areReportsLoading && !getters.anyReportHasError) {
    text.push('(is loading)');
  } else if (!getters.areReportsLoading && getters.anyReportHasError) {
    text.push('(errors when loading results)');
  }

  if (added > 0 && fixed === 0) {
    text.push(n__('detected %d new vulnerability', 'detected %d new vulnerabilities', added));
  }

  if (added > 0 && fixed > 0) {
    text.push(
      `${n__('detected %d new vulnerability', 'detected %d new vulnerabilities', added)} ${n__(
        'and %d fixed vulnerability',
        'and %d fixed vulnerabilities',
        fixed,
      )}`,
    );
  }

  if (added === 0 && fixed > 0) {
    text.push(n__('detected %d fixed vulnerability', 'detected %d fixed vulnerabilities', fixed));
  }

  if (added === 0 && fixed === 0) {
    text.push(s__('detected no vulnerabilities'));
  }
  return text.join(' ');
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

export const sastStatusIcon = ({ sast }) =>
  statusIcon(sast.isLoading, sast.hasError, sast.newIssues.length);

export const sastContainerStatusIcon = ({ sastContainer }) =>
  statusIcon(sastContainer.isLoading, sastContainer.hasError, sastContainer.newIssues.length);

export const dastStatusIcon = ({ dast }) =>
  statusIcon(dast.isLoading, dast.hasError, dast.newIssues.length);

export const dependencyScanningStatusIcon = ({ dependencyScanning }) =>
  statusIcon(
    dependencyScanning.isLoading,
    dependencyScanning.hasError,
    dependencyScanning.newIssues.length,
  );

export const areReportsLoading = state =>
  state.sast.isLoading ||
  state.dast.isLoading ||
  state.sastContainer.isLoading ||
  state.dependencyScanning.isLoading;

export const areAllReportsLoading = state =>
  state.sast.isLoading &&
  state.dast.isLoading &&
  state.sastContainer.isLoading &&
  state.dependencyScanning.isLoading;

export const allReportsHaveError = state =>
  state.sast.hasError &&
  state.dast.hasError &&
  state.sastContainer.hasError &&
  state.dependencyScanning.hasError;

export const anyReportHasError = state =>
  state.sast.hasError ||
  state.dast.hasError ||
  state.sastContainer.hasError ||
  state.dependencyScanning.hasError;

export const noBaseInAllReports = state =>
  !state.sast.paths.base &&
  !state.dast.paths.base &&
  !state.sastContainer.paths.base &&
  !state.dependencyScanning.paths.base;

export const anyReportHasIssues = state =>
  state.sast.newIssues.length > 0 ||
  state.dast.newIssues.length > 0 ||
  state.sastContainer.newIssues.length > 0 ||
  state.dependencyScanning.newIssues.length > 0;
