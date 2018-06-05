import sha1 from 'sha1';
import _ from 'underscore';
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
 * feedback (`dismissal` or `issue` type)
 * @param {Object} vulnerability
 * @param {Array} feedback
 */
function enrichVulnerabilityWithfeedback(vulnerability, feedback = []) {
  return feedback.filter(
    fb => fb.project_fingerprint === vulnerability.project_fingerprint,
  ).reduce((vuln, fb) => {
    if (fb.feedback_type === 'dismissal') {
      return {
        ...vuln,
        isDismissed: true,
        dismissalFeedback: fb,
      };
    } else if (fb.feedback_type === 'issue') {
      return {
        ...vuln,
        hasIssue: true,
        issueFeedback: fb,
      };
    }
    return vuln;
  }, vulnerability);
}

/**
 * Generates url to repository file and highlight section between start and end lines.
 *
 * @param {Object} location
 * @param {String} pathPrefix
 * @returns {String}
 */
function fileUrl(location, pathPrefix) {
  let lineSuffix = '';
  if (!_.isEmpty(location.start_line)) {
    lineSuffix += `#L${location.start_line}`;
    if (!_.isEmpty(location.end_line)) {
      lineSuffix += `-${location.end_line}`;
    }
  }
  return `${pathPrefix}/${location.file}${lineSuffix}`;
}

/**
 * Parses issues with deprecated JSON format and adapts it to the new one.
 *
 * @param {Object} issue
 * @returns {Object}
 */
function adaptDeprecatedFormat(issue) {
  // Skip issue with new format (old format does not have a location property)
  if (issue.location) {
    return issue;
  }

  const adapted = {
    ...issue,
  };

  // Add the new links property
  const links = [];
  if (!_.isEmpty(adapted.url)) {
    links.push({ url: adapted.url });
  }

  Object.assign(adapted, {
    // Add the new location property
    location: {
      file: adapted.file,
      start_line: adapted.line,
    },
    links,
  });

  return adapted;
}

/**
 * Parses SAST results into a common format to allow to use the same Vue component.
 *
 * @param {Array} issues
 * @param {Array} feedback
 * @param {String} path
 * @returns {Array}
 */
export const parseSastIssues = (issues = [], feedback = [], path = '') =>
  issues.map(issue => {
    const parsed = {
      ...adaptDeprecatedFormat(issue),
      category: 'sast',
      project_fingerprint: sha1(issue.cve),
      title: issue.message,
    };

    return {
      ...parsed,
      path: parsed.location.file,
      urlPath: fileUrl(parsed.location, path),
      ...enrichVulnerabilityWithfeedback(parsed, feedback),
    };
  });

/**
 * Parses Dependency Scanning results into a common format to allow to use the same Vue component.
 *
 * @param {Array} issues
 * @param {Array} feedback
 * @param {String} path
 * @returns {Array}
 */
export const parseDependencyScanningIssues = (issues = [], feedback = [], path = '') =>
  issues.map(issue => {
    const parsed = {
      ...adaptDeprecatedFormat(issue),
      category: 'dependency_scanning',
      project_fingerprint: sha1(issue.cve || issue.message),
      title: issue.message,
    };

    return {
      ...parsed,
      path: parsed.location.file,
      urlPath: fileUrl(parsed.location, path),
      ...enrichVulnerabilityWithfeedback(parsed, feedback),
    };
  });

/**
 * Parses Container Scanning results into a common format to allow to use the same Vue component.
 * Container Scanning report is currently the straigh output from the underlying tool
 * (clair scanner) hence the formatting happenning here.
 *
 * @param {Array} issues
 * @param {Array} feedback
 * @param {String} path
 * @returns {Array}
 */
export const parseSastContainer = (issues = [], feedback = []) =>
  issues.map(issue => {
    const parsed = {
      ...issue,
      category: 'container_scanning',
      project_fingerprint: sha1(`${issue.namespace}:${issue.vulnerability}:${issue.featurename}:${issue.featureversion}`),
      title: issue.vulnerability,
      description: !_.isEmpty(issue.description) ? issue.description :
        sprintf(s__('ciReport|%{namespace} is affected by %{vulnerability}.'), {
          namespace: issue.namespace,
          vulnerability: issue.vulnerability,
        }),
      path: issue.namespace,
      identifiers: [{
        type: 'CVE',
        name: issue.vulnerability,
        value: issue.vulnerability,
        url: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${issue.vulnerability}`,
      }],
    };

    // Generate solution
    if (!_.isEmpty(issue.fixedby) &&
      !_.isEmpty(issue.featurename) &&
      !_.isEmpty(issue.featureversion)
    ) {
      Object.assign(parsed, {
        solution: sprintf(s__('ciReport|Upgrade %{name} from %{version} to %{fixed}.'), {
          name: issue.featurename,
          version: issue.featureversion,
          fixed: issue.fixedby,
        }),
      });
    }

    return {
      ...parsed,
      ...enrichVulnerabilityWithfeedback(parsed, feedback),
    };
  });

/**
 * Parses DAST into a common format to allow to use the same Vue component.
 * DAST report is currently the straigh output from the underlying tool (ZAProxy)
 * hence the formatting happenning here.
 *
 * @param {Array} issues
 * @param {Array} feedback
 * @returns {Array}
 */
export const parseDastIssues = (issues = [], feedback = []) =>
  issues.map(issue => {
    const parsed = {
      ...issue,
      category: 'dast',
      project_fingerprint: sha1(issue.pluginid),
      title: issue.name,
      description: stripHtml(issue.desc, ' '),
      solution: stripHtml(issue.solution, ' '),
    };

    if (!_.isEmpty(issue.cweid)) {
      Object.assign(parsed, {
        identifiers: [{
          type: 'CWE',
          name: `CWE-${issue.cweid}`,
          value: issue.cweid,
          url: `https://cwe.mitre.org/data/definitions/${issue.cweid}.html`,
        }],
      });
    }

    if (issue.riskdesc && issue.riskdesc !== '') {
      // Split riskdesc into severity and confidence.
      // Riskdesc format is: "severity (confidence)"
      const [, severity, confidence] = issue.riskdesc.match(/(.*) \((.*)\)/);
      Object.assign(parsed, {
        severity,
        confidence,
      });
    }

    return {
      ...parsed,
      ...enrichVulnerabilityWithfeedback(parsed, feedback),
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
