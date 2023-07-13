import { SEVERITIES as SEVERITIES_CODE_QUALITY } from '~/ci/reports/codequality_report/constants';
import { SEVERITIES as SEVERITIES_SAST } from '~/ci/reports/sast/constants';
import { SAST_SCALE_KEY } from './constants';

function mapSeverity(findings) {
  const severityInfo =
    findings.scale === SAST_SCALE_KEY ? SEVERITIES_SAST : SEVERITIES_CODE_QUALITY;
  return {
    ...findings,
    class: severityInfo[findings.severity].class,
    name: severityInfo[findings.severity].name,
  };
}

export function getSeverity(findings) {
  if (Array.isArray(findings)) {
    return findings.map((finding) => mapSeverity(finding));
  }
  return mapSeverity(findings);
}
