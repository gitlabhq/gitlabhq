import { n__, s__, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { SEVERITY_ICONS_MR_WIDGET } from '~/ci/reports/codequality_report/constants';

/**
 * Returns the appropriate summary text based on code quality report findings.
 * @param {Object} params - Parameters for determining summary text
 * @param {number} params.newCount - Number of new code quality findings
 * @param {number} params.resolvedCount - Number of resolved code quality findings
 * @returns {string} Localized summary text for the code quality report
 */
export const codeQualitySummary = ({ newCount, resolvedCount }) => {
  if (newCount >= 1 && resolvedCount >= 1) {
    const newFindings = sprintf(
      n__(
        'ciReport|%{strong_start}%{count}%{strong_end} new finding',
        'ciReport|%{strong_start}%{count}%{strong_end} new findings',
        newCount,
      ),
      { count: newCount },
      false,
    );
    const resolvedFindings = sprintf(
      n__(
        'ciReport|%{strong_start}%{count}%{strong_end} fixed finding',
        'ciReport|%{strong_start}%{count}%{strong_end} fixed findings',
        resolvedCount,
      ),
      { count: resolvedCount },
      false,
    );
    return sprintf(
      s__('ciReport|Code Quality scans found %{newFindings} and %{resolvedFindings}.'),
      { newFindings, resolvedFindings },
      false,
    );
  }

  if (resolvedCount >= 1) {
    return sprintf(
      n__(
        'ciReport|Code Quality scans found %{strong_start}%{count}%{strong_end} fixed finding.',
        'ciReport|Code Quality scans found %{strong_start}%{count}%{strong_end} fixed findings.',
        resolvedCount,
      ),
      { count: resolvedCount },
      false,
    );
  }

  if (newCount >= 1) {
    return sprintf(
      n__(
        'ciReport|Code Quality scans found %{strong_start}%{count}%{strong_end} new finding.',
        'ciReport|Code Quality scans found %{strong_start}%{count}%{strong_end} new findings.',
        newCount,
      ),
      { count: newCount },
      false,
    );
  }

  return s__("ciReport|Code Quality hasn't changed.");
};

const baseCodeQualityFinding = (finding) => ({
  text: finding.engine_name
    ? `${capitalizeFirstCharacter(finding.severity)} - ${finding.engine_name} - ${finding.description}`
    : `${capitalizeFirstCharacter(finding.severity)} - ${finding.description}`,
  icon: { name: SEVERITY_ICONS_MR_WIDGET[finding.severity] },
});

/**
 * Transforms a new code quality finding from the API into a format suitable for report_section.vue.
 * @param {Object} finding - Raw code quality finding from the codequality_reports API
 * @returns {Object} Transformed finding with text, icon, and link to the file
 * @example
 * transformNewCodeQualityFinding({
 *   description: 'Method has too many lines',
 *   severity: 'major',
 *   file_path: 'src/foo.js',
 *   line: 42,
 *   web_url: 'https://gitlab.com/project/-/blob/main/src/foo.js#L42',
 *   engine_name: 'eslint',
 * });
 * // Returns: { text: 'Major - eslint - Method has too many lines', icon: {...}, link: {...} }
 */
export const transformNewCodeQualityFinding = (finding) => ({
  ...baseCodeQualityFinding(finding),
  link: {
    href: finding.web_url, // eslint-disable-line local-rules/no-web-url
    text: `${s__('ciReport|in')} ${finding.file_path}:${finding.line}`,
  },
});

/**
 * Transforms a resolved code quality finding from the API into a format suitable for report_section.vue.
 * @param {Object} finding - Raw code quality finding from the codequality_reports API
 * @returns {Object} Transformed finding with text, icon, supportingText, and a "Fixed" badge
 * @example
 * transformResolvedCodeQualityFinding({
 *   description: 'Method has too many lines',
 *   severity: 'major',
 *   file_path: 'src/foo.js',
 *   line: 42,
 *   engine_name: 'eslint',
 * });
 * // Returns: { text: 'Major - eslint - Method has too many lines', icon: {...}, supportingText: '...', badge: {...} }
 */
export const transformResolvedCodeQualityFinding = (finding) => ({
  ...baseCodeQualityFinding(finding),
  supportingText: `${s__('ciReport|in')} ${finding.file_path}:${finding.line}`,
  badge: {
    variant: 'neutral',
    text: s__('ciReport|Fixed'),
  },
});
