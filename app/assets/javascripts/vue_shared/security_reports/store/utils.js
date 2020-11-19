import pollUntilComplete from '~/lib/utils/poll_until_complete';
import axios from '~/lib/utils/axios_utils';
import {
  FEEDBACK_TYPE_DISMISSAL,
  FEEDBACK_TYPE_ISSUE,
  FEEDBACK_TYPE_MERGE_REQUEST,
} from '../constants';

export const fetchDiffData = (state, endpoint, category) => {
  const requests = [pollUntilComplete(endpoint)];

  if (state.canReadVulnerabilityFeedback) {
    requests.push(axios.get(state.vulnerabilityFeedbackPath, { params: { category } }));
  }

  return Promise.all(requests).then(([diffResponse, enrichResponse]) => ({
    diff: diffResponse.data,
    enrichData: enrichResponse?.data ?? [],
  }));
};

/**
 * Returns given vulnerability enriched with the corresponding
 * feedback (`dismissal` or `issue` type)
 * @param {Object} vulnerability
 * @param {Array} feedback
 */
export const enrichVulnerabilityWithFeedback = (vulnerability, feedback = []) =>
  feedback
    .filter(fb => fb.project_fingerprint === vulnerability.project_fingerprint)
    .reduce((vuln, fb) => {
      if (fb.feedback_type === FEEDBACK_TYPE_DISMISSAL) {
        return {
          ...vuln,
          isDismissed: true,
          dismissalFeedback: fb,
        };
      }
      if (fb.feedback_type === FEEDBACK_TYPE_ISSUE && fb.issue_iid) {
        return {
          ...vuln,
          hasIssue: true,
          issue_feedback: fb,
        };
      }
      if (fb.feedback_type === FEEDBACK_TYPE_MERGE_REQUEST && fb.merge_request_iid) {
        return {
          ...vuln,
          hasMergeRequest: true,
          merge_request_feedback: fb,
        };
      }
      return vuln;
    }, vulnerability);

/**
 * Generates the added, fixed, and existing vulnerabilities from the API report.
 *
 * @param {Object} diff The original reports.
 * @param {Object} enrichData Feedback data to add to the reports.
 * @returns {Object}
 */
export const parseDiff = (diff, enrichData) => {
  const enrichVulnerability = vulnerability => ({
    ...enrichVulnerabilityWithFeedback(vulnerability, enrichData),
    category: vulnerability.report_type,
    title: vulnerability.message || vulnerability.name,
  });

  return {
    added: diff.added ? diff.added.map(enrichVulnerability) : [],
    fixed: diff.fixed ? diff.fixed.map(enrichVulnerability) : [],
    existing: diff.existing ? diff.existing.map(enrichVulnerability) : [],
  };
};
