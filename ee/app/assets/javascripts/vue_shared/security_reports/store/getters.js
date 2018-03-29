import { n__, s__ } from '~/locale';
import { textBuilder, statusIcon } from './utils';

export const groupedSastText = ({ sast }) =>
  textBuilder(
    'SAST',
    sast.paths,
    sast.newIssues.length,
    sast.resolvedIssues.length,
    sast.allIssues.length,
  );

export const groupedSastContainerText = ({ sastContainer }) =>
  textBuilder(
    'Container scanning',
    sastContainer.paths,
    sastContainer.newIssues.length,
    sastContainer.resolvedIssues.length,
  );

export const groupedDastText = ({ dast }) =>
  textBuilder('DAST', dast.paths, dast.newIssues.length, dast.resolvedIssues.length);

export const groupedDependencyText = ({ dependencyScanning }) =>
  textBuilder(
    'Dependency scanning',
    dependencyScanning.paths,
    dependencyScanning.newIssues.length,
    dependencyScanning.resolvedIssues.length,
  );

export const groupedSummaryText = (state, getters) => {
  const { added, fixed } = state.summaryCounts;
  // All reports returned error
  if (getters.allReportsHaveError) {
    return s__('ciReport|Security scanning failed loading any results');
  }

  // No base is present in any report
  if (getters.noBaseInAllReports) {
    if (added > 0) {
      return n__(
        'Security scanning was unable to compare existing and new vulnerabilities. It detected %d vulnerability',
        'Security scanning was unable to compare existing and new vulnerabilities. It detected %d vulnerabilities',
        added,
      );
    }

    return s__(
      'Security scanning was unable to compare existing and new vulnerabilities. It detected no vulnerabilities.',
    );
  }

  const text = [s__('ciReport|Security scanning')];

  if (getters.areReportsLoading) {
    text.push('(in progress)');
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

export const sastStatusIcon = ({ sast }) => statusIcon(sast.hasError, sast.newIssues.length);

export const sastContainerStatusIcon = ({ sastContainer }) =>
  statusIcon(sastContainer.hasError, sastContainer.newIssues.length);

export const dastStatusIcon = ({ dast }) => statusIcon(dast.hasError, dast.newIssues.length);

export const dependencyScanningStatusIcon = ({ dependencyScanning }) =>
  statusIcon(dependencyScanning.hasError, dependencyScanning.newIssues.length);

export const areReportsLoading = state =>
  state.sast.isLoading ||
  state.dast.isLoading ||
  state.sastContainer.isLoading ||
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
