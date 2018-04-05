import { stripHtml } from '~/lib/utils/text_utility';
import { n__, s__, sprintf } from '~/locale';

/**
 * Maps SAST & Dependency scanning issues:
 * { tool: String, message: String, url: String , cve: String ,
 * file: String , solution: String, priority: String }
 * to contain:
 * { name: String, path: String, line: String, urlPath: String, priority: String }
 * @param {Array} issues
 * @param {String} path
 */
export const parseSastIssues = (issues = [], path = '') =>
  issues.map(issue => ({
    ...issue,
    name: issue.message,
    path: issue.file,
    urlPath: issue.line ? `${path}/${issue.file}#L${issue.line}` : `${path}/${issue.file}`,
  }),
);

/**
 * Parses Sast Container results into a common format to allow to use the same Vue component
 * And adds an external link
 *
 * @param {Array} data
 * @returns {Array}
 */
export const parseSastContainer = (data = []) =>
  data.map(element => ({
    ...element,
    name: element.vulnerability,
    priority: element.severity,
    path: element.namespace,
    // external link to provide better description
    nameLink: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${element.vulnerability}`,
  }));

export const parseDastIssues = (issues = []) =>
  issues.map(issue => ({
    parsedDescription: stripHtml(issue.desc, ' '),
    priority: issue.riskdesc,
    ...issue,
  }));

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

    return sprintf(
      '%{type} detected no vulnerabilities for the source branch only',
      { type },
    );
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
