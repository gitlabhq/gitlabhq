import { stripHtml } from '~/lib/utils/text_utility';

/**
 * Parses SAST and Codeclimate Issues into a common and reusable format
 * to reuse the same vue component.
 * [
 *   {
 *     name: String,
 *     priority: String,
 *     fingerprint: String,
 *     path: String,
 *     line: Number,
 *     urlPath: String
 *   }
 * ]
 * @param {array} issues
 * @return {array}
 */
export const parseIssues = (issues = [], path = '') => issues.map((issue) => {
  const parsedIssue = {
    name: issue.description || issue.message,
    ...issue,
  };

  // code quality
  if (issue.location) {
    let parseCodeQualityUrl;

    if (issue.location.path) {
      parseCodeQualityUrl = `${path}/${issue.location.path}`;
      parsedIssue.path = issue.location.path;
    }

    if (issue.location.lines && issue.location.lines.begin) {
      parsedIssue.line = issue.location.lines.begin;
      parseCodeQualityUrl += `#L${issue.location.lines.begin}`;
    }

    parsedIssue.urlPath = parseCodeQualityUrl;

  // security
  } else if (issue.file) {
    let parsedSecurityUrl = `${path}/${issue.file}`;
    parsedIssue.path = issue.file;

    if (issue.line) {
      parsedSecurityUrl += `#L${issue.line}`;
    }
    parsedIssue.urlPath = parsedSecurityUrl;
  }

  return parsedIssue;
});

/**
 * Compares two arrays by the given key and returns the difference
 *
 * @param {Array} firstArray
 * @param {Array} secondArray
 * @param {String} key
 * @returns {Array}
 */
export const filterByKey = (firstArray = [], secondArray = [], key = '') => firstArray
  .filter(item => !secondArray.find(el => el[key] === item[key]));

/**
 * Parses DAST results into a common format to allow to use the same Vue component
 * And adds an external link
 *
 * @param {Array} data
 * @returns {Array}
 */
export const parseSastContainer = (data = []) => data.map(el => ({
  name: el.vulnerability,
  priority: el.severity,
  path: el.namespace,
  // external link to provide better description
  nameLink: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${el.vulnerability}`,
  ...el,
}));

/**
 * Utils functions to set the reports
 */

/**
 * Compares sast results and returns the formatted report
 *
 * Security report has 3 types of issues, newIssues, resolvedIssues and allIssues.
 *
 * When we have both base and head:
 * - newIssues = head - base
 * - resolvedIssues = base - head
 * - allIssues = head - newIssues - resolvedIssues
 *
 * When we only have head
 * - newIssues = head
 * - resolvedIssues = 0
 * - allIssues = 0
 * @param {*} data
 * @returns {Object}
 */
export const setSastReport = (data = {}) => {
  const securityReport = {};

  if (data.base) {
    const filterKey = 'cve';
    const parsedHead = parseIssues(data.head, data.headBlobPath);
    const parsedBase = parseIssues(data.base, data.baseBlobPath);

    securityReport.newIssues = filterByKey(
      parsedHead,
      parsedBase,
      filterKey,
    );
    securityReport.resolvedIssues = filterByKey(
      parsedBase,
      parsedHead,
      filterKey,
    );

    // Remove the new Issues and the added issues
    securityReport.allIssues = filterByKey(
      parsedHead,
      securityReport.newIssues.concat(securityReport.resolvedIssues),
      filterKey,
    );
  } else {
    securityReport.newIssues = parseIssues(data.head, data.headBlobPath);
  }

  return securityReport;
};

export const setSastContainerReport = (data = {}) => {
  const unapproved = data.unapproved || [];

  const parsedVulnerabilities = parseSastContainer(data.vulnerabilities);

  // Approved can be calculated by subtracting unapproved from vulnerabilities.
  return {
    vulnerabilities: parsedVulnerabilities || [],
    approved: parsedVulnerabilities
    .filter(item => !unapproved.find(el => el === item.vulnerability)) || [],
    unapproved: parsedVulnerabilities
    .filter(item => unapproved.find(el => el === item.vulnerability)) || [],
  };
};

/**
 * Dast Report sends some keys in HTML, we need to strip the `<p>` tags.
 * This should be moved to the backend.
 *
 * @param {Array} data
 * @returns {Array}
 */
export const setDastReport = data => data.site.alerts.map(alert => ({
  name: alert.name,
  parsedDescription: stripHtml(alert.desc, ' '),
  priority: alert.riskdesc,
  ...alert,
}));
