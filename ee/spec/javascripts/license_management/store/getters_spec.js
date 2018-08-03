import * as getters from 'ee/vue_shared/license_management/store/getters';
import { parseLicenseReportMetrics } from 'ee/vue_shared/license_management/store/utils';

import {
  licenseHeadIssues,
  licenseBaseIssues,
  approvedLicense,
  licenseReport as licenseReportMock,
} from 'ee_spec/license_management/mock_data';

describe('getters', () => {
  describe('isLoading', () => {
    it('is true if `isLoadingManagedLicenses` is true OR `isLoadingLicenseReport` is true', () => {
      const state = {};
      state.isLoadingManagedLicenses = true;
      state.isLoadingLicenseReport = true;
      expect(getters.isLoading(state)).toBe(true);
      state.isLoadingManagedLicenses = false;
      state.isLoadingLicenseReport = true;
      expect(getters.isLoading(state)).toBe(true);
      state.isLoadingManagedLicenses = true;
      state.isLoadingLicenseReport = false;
      expect(getters.isLoading(state)).toBe(true);
      state.isLoadingManagedLicenses = false;
      state.isLoadingLicenseReport = false;
      expect(getters.isLoading(state)).toBe(false);
    });
  });

  describe('licenseReport', () => {
    it('returns empty array, if the reports are empty', () => {
      const state = { headReport: {}, baseReport: {}, managedLicenses: [] };
      expect(getters.licenseReport(state)).toEqual([]);
    });

    it('returns license report, if the license report is not loading', () => {
      const state = {
        headReport: licenseHeadIssues,
        baseReport: licenseBaseIssues,
        managedLicenses: [approvedLicense],
      };

      expect(getters.licenseReport(state)).toEqual(
        parseLicenseReportMetrics(licenseHeadIssues, licenseBaseIssues, [approvedLicense]),
      );
    });
  });

  describe('licenseSummaryText', () => {
    describe('when licenses exist on both the HEAD and the BASE', () => {
      const state = {
        loadLicenseReportError: null,
        headReport: licenseHeadIssues,
        baseReport: licenseBaseIssues,
      };

      it('should be `Loading license management report` text if isLoading', () => {
        const mockGetters = {};
        mockGetters.isLoading = true;
        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'Loading license management report',
        );
      });

      it('should be `Failed to load license management report` text if an error has happened', () => {
        const mockGetters = {};
        expect(
          getters.licenseSummaryText({ loadLicenseReportError: new Error('Test') }, mockGetters),
        ).toBe('Failed to load license management report');
      });

      it('should be `License management detected no new licenses`, if the report is empty', () => {
        const mockGetters = { licenseReport: [] };
        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'License management detected no new licenses',
        );
      });

      it('should be `License management detected 1 new license`, if the report has one element', () => {
        const mockGetters = { licenseReport: [licenseReportMock[0]] };
        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'License management detected 1 new license',
        );
      });

      it('should be `License management detected 2 new licenses`, if the report has two elements', () => {
        const mockGetters = { licenseReport: [licenseReportMock[0], licenseReportMock[0]] };
        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'License management detected 2 new licenses',
        );
      });
    });

    describe('when there are no licences on the BASE', () => {
      const state = { baseReport: {} };

      it('should be `License management detected no licenses for the source branch only` with no new licences', () => {
        const mockGetters = { licenseReport: [] };

        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'License management detected no licenses for the source branch only',
        );
      });

      it('should be `License management detected 1 license for the source branch only` with one new licence', () => {
        const mockGetters = { licenseReport: [licenseReportMock[0]] };

        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'License management detected 1 license for the source branch only',
        );
      });

      it('should be `License management detected 2 licenses for the source branch only` with two new licences', () => {
        const mockGetters = { licenseReport: [licenseReportMock[0], licenseReportMock[0]] };

        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'License management detected 2 licenses for the source branch only',
        );
      });
    });
  });
});
