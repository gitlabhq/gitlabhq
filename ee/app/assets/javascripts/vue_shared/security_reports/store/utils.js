import sha1 from 'sha1';
import { stripHtml } from '~/lib/utils/text_utility';
import { n__, s__, sprintf } from '~/locale';

/**
 * Returns the index of an issue in given list
 * @param {Array} issues
 * @param {Object} issue
 */
export const findIssueIndex = (issues, issue) =>
  issues.findIndex(el => el.project_fingerprint === issue.project_fingerprint);

/**
 * Returns given vulnerability enriched with the corresponding
 * feedbacks (`dismissal` or `issue` type)
 * @param {Object} vulnerability
 * @param {Array} feedbacks
 */
function enrichVulnerabilityWithfeedbacks(vulnerability, feedbacks = []) {
  return feedbacks.filter(
    feedback => feedback.project_fingerprint === vulnerability.project_fingerprint,
  ).reduce((vuln, feedback) => {
    if (feedback.feedback_type === 'dismissal') {
      return {
        ...vuln,
        isDismissed: true,
        dismissalFeedback: feedback,
      };
    } else if (feedback.feedback_type === 'issue') {
      return {
        ...vuln,
        hasIssue: true,
        issueFeedback: feedback,
      };
    }
    return vuln;
  }, vulnerability);
}

/**
 * Maps SAST issues:
 * { tool: String, message: String, url: String , cve: String ,
 * file: String , solution: String, priority: String }
 * to contain:
 * { name: String, path: String, line: String, urlPath: String, priority: String }
 * @param {Array} issues
 * @param {String} path
 */
export const parseSastIssues = (issues = [], feedbacks = [], path = '') =>
  issues.map(issue => {
    const parsed = {
      ...issue,
      category: 'sast',
      // TODO: replace with issue.project_fingerprint
      project_fingerprint: sha1(issue.cve),
      name: issue.message,
      path: issue.file,
      urlPath: issue.line ? `${path}/${issue.file}#L${issue.line}` : `${path}/${issue.file}`,
    };

    return {
      ...parsed,
      ...enrichVulnerabilityWithfeedbacks(parsed, feedbacks),
    };
  });

/**
 * Maps Dependency scanning issues:
 * { tool: String, message: String, url: String , cve: String ,
 * file: String , solution: String, priority: String }
 * to contain:
 * { name: String, path: String, line: String, urlPath: String, priority: String }
 * @param {Array} issues
 * @param {String} path
 */
export const parseDependencyScanningIssues = (issues = [], feedbacks = [], path = '') =>
  issues.map(issue => {
    const parsed = {
      ...issue,
      category: 'dependency_scanning',
      // TODO: replace with issue.project_fingerprint
      project_fingerprint: sha1(issue.cve || issue.message),
      name: issue.message,
      path: issue.file,
      urlPath: issue.line ? `${path}/${issue.file}#L${issue.line}` : `${path}/${issue.file}`,
    };

    return {
      ...parsed,
      ...enrichVulnerabilityWithfeedbacks(parsed, feedbacks),
    };
  });

/**
 * Parses Sast Container results into a common format to allow to use the same Vue component
 * And adds an external link
 *
 * @param {Array} data
 * @returns {Array}
 */
export const parseSastContainer = (issues = [], feedbacks = []) =>
  issues.map(issue => {
    const parsed = {
      ...issue,
      category: 'container_scanning',
      // TODO: replace with issue.project_fingerprint
      project_fingerprint: sha1(`${issue.namespace}:${issue.vulnerability}:${issue.featurename}:${issue.featureversion}`),
      name: issue.vulnerability,
      priority: issue.severity,
      path: issue.namespace,
      // external link to provide better description
      nameLink: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${issue.vulnerability}`,
    };

    return {
      ...parsed,
      ...enrichVulnerabilityWithfeedbacks(parsed, feedbacks),
    };
  });

export const parseDastIssues = (issues = [], feedbacks = []) =>
  issues.map(issue => {
    const parsed = {
      ...issue,
      category: 'dast',
      // TODO: replace with issue.project_fingerprint
      project_fingerprint: sha1(issue.pluginid),
      parsedDescription: stripHtml(issue.desc, ' '),
      priority: issue.riskdesc,
      solution: stripHtml(issue.solution, ' '),
      description: stripHtml(issue.desc, ' '),
    };

    if (issue.cweid && issue.cweid !== '') {
      Object.assign(parsed, {
        identifier: `CWE-${issue.cweid}`,
      });
    }

    if (issue.riskdesc && issue.riskdesc !== '') {
      // Split 'severity (confidence)'
      const [, severity, confidence] = issue.riskdesc.match(/(.*) \((.*)\)/);
      Object.assign(parsed, {
        severity,
        confidence,
      });
    }

    return {
      ...parsed,
      ...enrichVulnerabilityWithfeedbacks(parsed, feedbacks),
    };
  });

/**
 * Compares two arrays by the given key and returns the difference
 *
 * @param {Array} firstArray
 * @param {Array} secondArray
 * @param {String} key
 * @returns {Array}
 */
export const filterByKey = (firstArray = [], secondArray = [], key = '') =>
  firstArray.filter(item => !secondArray.find(el => el[key] === item[key]));

export const getUnapprovedVulnerabilities = (issues = [], unapproved = []) =>
  issues.filter(item => unapproved.find(el => el === item.vulnerability));

export const textBuilder = (
  type = '',
  paths = {},
  newIssues = 0,
  resolvedIssues = 0,
  allIssues = 0,
) => {
  // with no new or fixed but with vulnerabilities
  if (newIssues === 0 && resolvedIssues === 0 && allIssues) {
    return sprintf(s__('ciReport|%{type} detected no new security vulnerabilities'), { type });
  }

  if (!paths.base) {
    if (newIssues > 0) {
      return sprintf(
        n__(
          '%{type} detected %d vulnerability for the source branch only',
          '%{type} detected %d vulnerabilities for the source branch only',
          newIssues,
        ),
        { type },
      );
    }

    return sprintf('%{type} detected no vulnerabilities for the source branch only', { type });
  } else if (paths.base && paths.head) {
    // With no issues
    if (newIssues === 0 && resolvedIssues === 0 && allIssues === 0) {
      return sprintf(s__('ciReport|%{type} detected no security vulnerabilities'), { type });
    }

    // with only new issues
    if (newIssues > 0 && resolvedIssues === 0) {
      return sprintf(
        n__(
          '%{type} detected %d new vulnerability',
          '%{type} detected %d new vulnerabilities',
          newIssues,
        ),
        { type },
      );
    }

    // with new and fixed issues
    if (newIssues > 0 && resolvedIssues > 0) {
      return `${sprintf(
        n__(
          '%{type} detected %d new vulnerability',
          '%{type} detected %d new vulnerabilities',
          newIssues,
        ),
        { type },
      )}
      ${n__('and %d fixed vulnerability', 'and %d fixed vulnerabilities', resolvedIssues)}`;
    }

    // with only fixed issues
    if (newIssues === 0 && resolvedIssues > 0) {
      return sprintf(
        n__(
          '%{type} detected %d fixed vulnerability',
          '%{type} detected %d fixed vulnerabilities',
          resolvedIssues,
        ),
        { type },
      );
    }
  }
  return '';
};

export const statusIcon = (loading = false, failed = false, newIssues = 0, neutralIssues = 0) => {
  if (loading) {
    return 'loading';
  }

  if (failed || newIssues > 0 || neutralIssues > 0) {
    return 'warning';
  }

  return 'success';
};
