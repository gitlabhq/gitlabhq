import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
  REPORT_FILE_TYPES,
} from '~/vue_shared/security_reports/constants';
import {
  extractSecurityReportArtifactsFromMergeRequest,
  extractSecurityReportArtifactsFromPipeline,
} from '~/vue_shared/security_reports/utils';
import {
  securityReportMergeRequestDownloadPathsQueryResponse,
  securityReportPipelineDownloadPathsQueryResponse,
  sastArtifacts,
  secretDetectionArtifacts,
  archiveArtifacts,
  traceArtifacts,
  metadataArtifacts,
} from './mock_data';

describe.each([
  [
    'extractSecurityReportArtifactsFromMergeRequest',
    extractSecurityReportArtifactsFromMergeRequest,
    securityReportMergeRequestDownloadPathsQueryResponse,
  ],
  [
    'extractSecurityReportArtifactsFromPipelines',
    extractSecurityReportArtifactsFromPipeline,
    securityReportPipelineDownloadPathsQueryResponse,
  ],
])('%s', (funcName, extractFunc, response) => {
  it.each`
    reportTypes                                         | expectedArtifacts
    ${[]}                                               | ${[]}
    ${['foo']}                                          | ${[]}
    ${[REPORT_TYPE_SAST]}                               | ${sastArtifacts}
    ${[REPORT_TYPE_SECRET_DETECTION]}                   | ${secretDetectionArtifacts}
    ${[REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION]} | ${[...secretDetectionArtifacts, ...sastArtifacts]}
    ${[REPORT_FILE_TYPES.ARCHIVE]}                      | ${archiveArtifacts}
    ${[REPORT_FILE_TYPES.TRACE]}                        | ${traceArtifacts}
    ${[REPORT_FILE_TYPES.METADATA]}                     | ${metadataArtifacts}
  `(
    'returns the expected artifacts given report types $reportTypes',
    ({ reportTypes, expectedArtifacts }) => {
      expect(extractFunc(reportTypes, response)).toEqual(expectedArtifacts);
    },
  );
});
