import { SEVERITIES as SEVERITIES_CODE_QUALITY } from '~/ci/reports/codequality_report/constants';
import { SEVERITIES as SEVERITIES_SAST } from '~/ci/reports/sast/constants';

export const failedReport = {
  summary: { total: 11, resolved: 0, errored: 2, failed: 0 },
  suites: [
    {
      name: 'rspec:pg',
      status: 'error',
      summary: { total: 0, resolved: 0, errored: 0, failed: 0 },
      new_failures: [],
      resolved_failures: [],
      existing_failures: [],
      new_errors: [],
      resolved_errors: [],
      existing_errors: [],
    },
  ],
};

export const findingSastInfo = {
  scale: 'sast',
  severity: 'info',
};

export const findingSastInfoEnhanced = {
  scale: 'sast',
  severity: 'info',
  class: SEVERITIES_SAST.info.class,
  name: SEVERITIES_SAST.info.name,
};

const findingsCodeQualityBlocker = {
  scale: 'codeQuality',
  severity: 'blocker',
};

const findingCodeQualityBlockerEnhanced = {
  scale: 'codeQuality',
  severity: 'blocker',
  class: SEVERITIES_CODE_QUALITY.blocker.class,
  name: SEVERITIES_CODE_QUALITY.blocker.name,
};

export const findingCodeQualityInfo = {
  scale: 'codeQuality',
  severity: 'info',
};

export const findingCodeQualityInfoEnhanced = {
  scale: 'codeQuality',
  severity: 'info',
  class: SEVERITIES_CODE_QUALITY.info.class,
  name: SEVERITIES_CODE_QUALITY.info.name,
};

export const findingUnknownInfo = {
  scale: 'codeQuality',
  severity: 'info',
};

export const findingUnknownInfoEnhanced = {
  scale: 'codeQuality',
  severity: 'info',
  class: SEVERITIES_CODE_QUALITY.info.class,
  name: SEVERITIES_CODE_QUALITY.info.name,
};

export const findingsArray = [findingSastInfo, findingsCodeQualityBlocker];
export const findingsArrayEnhanced = [findingSastInfoEnhanced, findingCodeQualityBlockerEnhanced];
