import { n__, s__, sprintf } from '~/locale';
import { parseLicenseReportMetrics } from './utils';

export const isLoading = state => state.isLoadingManagedLicenses || state.isLoadingLicenseReport;

export const licenseReport = state =>
  parseLicenseReportMetrics(state.headReport, state.baseReport, state.managedLicenses);

export const licenseSummaryText = (state, getters) => {
  if (getters.isLoading) {
    return sprintf(s__('ciReport|Loading %{reportName} report'), {
      reportName: s__('license management'),
    });
  }

  if (state.loadLicenseReportError) {
    return sprintf(s__('ciReport|Failed to load %{reportName} report'), {
      reportName: s__('license management'),
    });
  }

  if (getters.licenseReport && getters.licenseReport.length > 0) {
    return n__(
      'ciReport|License management detected %d new license',
      'ciReport|License management detected %d new licenses',
      getters.licenseReport.length,
    );
  }

  return s__('ciReport|License management detected no new licenses');
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
