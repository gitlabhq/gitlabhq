import {
  groupedSummaryText,
  allReportsHaveError,
  areReportsLoading,
  anyReportHasError,
  areAllReportsLoading,
  anyReportHasIssues,
  summaryCounts,
} from '~/vue_shared/security_reports/store/getters';
import createSastState from '~/vue_shared/security_reports/store/modules/sast/state';
import createSecretScanningState from '~/vue_shared/security_reports/store/modules/secret_detection/state';
import createState from '~/vue_shared/security_reports/store/state';
import { groupedTextBuilder } from '~/vue_shared/security_reports/store/utils';
import { CRITICAL, HIGH, LOW } from '~/vulnerabilities/constants';

const generateVuln = (severity) => ({ severity });

describe('Security reports getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
    state.sast = createSastState();
    state.secretDetection = createSecretScanningState();
  });

  describe('summaryCounts', () => {
    it('returns 0 count for empty state', () => {
      expect(summaryCounts(state)).toEqual({
        critical: 0,
        high: 0,
        other: 0,
      });
    });

    describe('combines all reports', () => {
      it('of the same severity', () => {
        state.sast.newIssues = [generateVuln(CRITICAL)];
        state.secretDetection.newIssues = [generateVuln(CRITICAL)];

        expect(summaryCounts(state)).toEqual({
          critical: 2,
          high: 0,
          other: 0,
        });
      });

      it('of different severities', () => {
        state.sast.newIssues = [generateVuln(CRITICAL)];
        state.secretDetection.newIssues = [generateVuln(HIGH), generateVuln(LOW)];

        expect(summaryCounts(state)).toEqual({
          critical: 1,
          high: 1,
          other: 1,
        });
      });
    });
  });

  describe('groupedSummaryText', () => {
    it('returns failed text', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: true,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual({ message: 'Security scanning failed loading any results' });
    });

    it('returns `is loading` as status text', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          areReportsLoading: true,
          summaryCounts: {},
        }),
      ).toEqual(
        groupedTextBuilder({
          reportType: 'Security scanning',
          critical: 0,
          high: 0,
          other: 0,
          status: 'is loading',
        }),
      );
    });

    it('returns no new status text if there are existing ones', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual(
        groupedTextBuilder({
          reportType: 'Security scanning',
          critical: 0,
          high: 0,
          other: 0,
          status: '',
        }),
      );
    });
  });

  describe('areReportsLoading', () => {
    it('returns true when any report is loading', () => {
      state.sast.isLoading = true;

      expect(areReportsLoading(state)).toEqual(true);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areReportsLoading(state)).toEqual(false);
    });
  });

  describe('areAllReportsLoading', () => {
    it('returns true when all reports are loading', () => {
      state.sast.isLoading = true;
      state.secretDetection.isLoading = true;

      expect(areAllReportsLoading(state)).toEqual(true);
    });

    it('returns false when some of the reports are loading', () => {
      state.sast.isLoading = true;

      expect(areAllReportsLoading(state)).toEqual(false);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areAllReportsLoading(state)).toEqual(false);
    });
  });

  describe('allReportsHaveError', () => {
    it('returns true when all reports have error', () => {
      state.sast.hasError = true;
      state.secretDetection.hasError = true;

      expect(allReportsHaveError(state)).toEqual(true);
    });

    it('returns false when none of the reports have error', () => {
      expect(allReportsHaveError(state)).toEqual(false);
    });

    it('returns false when one of the reports does not have error', () => {
      state.secretDetection.hasError = true;

      expect(allReportsHaveError(state)).toEqual(false);
    });
  });

  describe('anyReportHasError', () => {
    it('returns true when any of the reports has error', () => {
      state.sast.hasError = true;

      expect(anyReportHasError(state)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasError(state)).toEqual(false);
    });
  });

  describe('anyReportHasIssues', () => {
    it('returns true when any of the reports has new issues', () => {
      state.sast.newIssues.push(generateVuln(LOW));

      expect(anyReportHasIssues(state)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasIssues(state)).toEqual(false);
    });
  });
});
