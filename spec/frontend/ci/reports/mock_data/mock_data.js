import { SEVERITIES as SEVERITIES_CODE_QUALITY } from '~/ci/reports/codequality_report/constants';
import { SEVERITIES as SEVERITIES_SAST } from '~/ci/reports/sast/constants';

export const failedIssue = {
  result: 'failure',
  name: 'Test#sum when a is 1 and b is 2 returns summary',
  execution_time: 0.009411,
  status: 'failed',
  system_output:
    "Failure/Error: is_expected.to eq(3)\n\n  expected: 3\n       got: -1\n\n  (compared using ==)\n./spec/test_spec.rb:12:in `block (4 levels) in \u003ctop (required)\u003e'",
  recent_failures: {
    count: 3,
    base_branch: 'main',
  },
};

export const successIssue = {
  result: 'success',
  name: 'Test#sum when a is 1 and b is 2 returns summary',
  execution_time: 0.009411,
  status: 'success',
  system_output: null,
  recent_failures: null,
};

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

export const findingsCodeQualityBlocker = {
  scale: 'codeQuality',
  severity: 'blocker',
};

export const findingCodeQualityBlockerEnhanced = {
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
