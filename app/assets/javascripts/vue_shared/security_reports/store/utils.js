import axios from '~/lib/utils/axios_utils';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { __, n__, sprintf } from '~/locale';
import { CRITICAL, HIGH } from '~/vulnerabilities/constants';
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
 * @param {Object} vulnerabilityObject
 * @param {Array} feedbackList
 */
export const enrichVulnerabilityWithFeedback = (vulnerabilityObject, feedbackList = []) => {
  const vulnerability = { ...vulnerabilityObject };
  // Some records may have a null `uuid`, we need to fallback to using `project_fingerprint` in those cases. Once all entries have been fixed, we can remove the fallback.
  // related epic: https://gitlab.com/groups/gitlab-org/-/epics/2791
  feedbackList
    .filter((fb) =>
      fb.finding_uuid
        ? fb.finding_uuid === vulnerability.uuid
        : fb.project_fingerprint === vulnerability.project_fingerprint,
    )
    .forEach((feedback) => {
      if (feedback.feedback_type === FEEDBACK_TYPE_DISMISSAL) {
        vulnerability.isDismissed = true;
        vulnerability.dismissalFeedback = feedback;
      } else if (feedback.feedback_type === FEEDBACK_TYPE_ISSUE && feedback.issue_iid) {
        vulnerability.hasIssue = true;
        vulnerability.issue_feedback = feedback;
      } else if (
        feedback.feedback_type === FEEDBACK_TYPE_MERGE_REQUEST &&
        feedback.merge_request_iid
      ) {
        vulnerability.hasMergeRequest = true;
        vulnerability.merge_request_feedback = feedback;
      }
    });

  return vulnerability;
};

/**
 * Generates the added, fixed, and existing vulnerabilities from the API report.
 *
 * @param {Object} diff The original reports.
 * @param {Object} enrichData Feedback data to add to the reports.
 * @returns {Object}
 */
export const parseDiff = (diff, enrichData) => {
  const enrichVulnerability = (vulnerability) => ({
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

const createCountMessage = ({ critical, high, other, total }) => {
  const otherMessage = n__('%d Other', '%d Others', other);
  const countMessage = __(
    '%{criticalStart}%{critical} Critical%{criticalEnd} %{highStart}%{high} High%{highEnd} and %{otherStart}%{otherMessage}%{otherEnd}',
  );
  return total ? sprintf(countMessage, { critical, high, otherMessage }) : '';
};

const createStatusMessage = ({ reportType, status, total }) => {
  const vulnMessage = n__('vulnerability', 'vulnerabilities', total);
  let message;
  if (status) {
    message = __('%{reportType} %{status}');
  } else if (!total) {
    message = __('%{reportType} detected no new vulnerabilities.');
  } else {
    message = __(
      '%{reportType} detected %{totalStart}%{total}%{totalEnd} potential %{vulnMessage}',
    );
  }
  return sprintf(message, { reportType, status, total, vulnMessage });
};

/**
 * Counts vulnerabilities.
 * Returns the amount of critical, high, and other vulnerabilities.
 *
 * @param {Array} vulnerabilities The raw vulnerabilities to parse
 * @returns {{critical: number, high: number, other: number}}
 */
export const countVulnerabilities = (vulnerabilities = []) =>
  vulnerabilities.reduce(
    (acc, { severity }) => {
      if (severity === CRITICAL) {
        acc.critical += 1;
      } else if (severity === HIGH) {
        acc.high += 1;
      } else {
        acc.other += 1;
      }

      return acc;
    },
    { critical: 0, high: 0, other: 0 },
  );

/**
 * Takes an object of options and returns the object with an externalized string representing
 * the critical, high, and other severity vulnerabilities for a given report.
 *
 * The resulting string _may_ still contain sprintf-style placeholders. These
 * are left in place so they can be replaced with markup, via the
 * SecuritySummary component.
 * @param {{reportType: string, status: string, critical: number, high: number, other: number}} options
 * @returns {Object} the parameters with an externalized string
 */
export const groupedTextBuilder = ({
  reportType = '',
  status = '',
  critical = 0,
  high = 0,
  other = 0,
} = {}) => {
  const total = critical + high + other;

  return {
    countMessage: createCountMessage({ critical, high, other, total }),
    message: createStatusMessage({ reportType, status, total }),
    critical,
    high,
    other,
    status,
    total,
  };
};
